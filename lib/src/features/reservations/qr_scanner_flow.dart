import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import 'reservation_dialog.dart';
import 'reservations_models.dart';
import 'reservations_repository.dart';

Future<void> startQrReservationFlow(BuildContext context) async {
  final controller = AppScope.of(context);
  final user = controller.currentUser;

  if (user == null) {
    return;
  }

  final canScanAnyQr = user.userCan(bookableResourcesQrScanPermission);

  if (!canScanAnyQr) {
    _showSnackBar(
      context,
      'Tu usuario no tiene permisos para escanear QRs desde la app.',
    );
    return;
  }

  final rawValue = await Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      fullscreenDialog: true,
      builder: (_) => const _QrScannerScreen(),
    ),
  );

  if (!context.mounted || rawValue == null || rawValue.trim().isEmpty) {
    return;
  }

  final repository = ReservationsRepository(controller.apiClient);
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  var isResolvingDialogVisible = false;

  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ResolvingQrDialog(),
    ),
  );
  isResolvingDialogVisible = true;

  try {
    final resolution = await repository.resolveQr(rawValue);

    if (isResolvingDialogVisible && context.mounted) {
      rootNavigator.pop();
      isResolvingDialogVisible = false;
    }

    if (!context.mounted) {
      return;
    }

    if (!user.userCan(resolution.type.info.reservePermission)) {
      _showSnackBar(
        context,
        'El QR corresponde a ${resolution.resourceTypeLabel.toLowerCase()}, pero tu usuario no puede reservar ese recurso.',
      );
      return;
    }

    if (resolution.resource.isDeleted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recurso no disponible'),
          content: Text(
            '${resolution.resource.name} ya no está disponible para nuevas reservas.',
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      return;
    }

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => ReservationDialog(
        type: resolution.type,
        resource: resolution.resource,
      ),
    );

    if (created == true && context.mounted) {
      _showSnackBar(
        context,
        'Reserva creada correctamente para ${resolution.resource.name}.',
      );
    }
  } on ApiException catch (error) {
    if (isResolvingDialogVisible && context.mounted) {
      rootNavigator.pop();
      isResolvingDialogVisible = false;
    }

    if (!context.mounted) {
      return;
    }

    await _showQrErrorDialog(context, collapseApiException(error));
  } on FormatException catch (error) {
    if (isResolvingDialogVisible && context.mounted) {
      rootNavigator.pop();
      isResolvingDialogVisible = false;
    }

    if (!context.mounted) {
      return;
    }

    await _showQrErrorDialog(context, error.message);
  } catch (_) {
    if (isResolvingDialogVisible && context.mounted) {
      rootNavigator.pop();
      isResolvingDialogVisible = false;
    }

    if (!context.mounted) {
      return;
    }

    await _showQrErrorDialog(context, 'No se pudo resolver el QR escaneado.');
  }
}

Future<void> _showQrErrorDialog(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('No se pudo leer el QR'),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _ResolvingQrDialog extends StatelessWidget {
  const _ResolvingQrDialog();

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: SizedBox(
        width: 260,
        child: FanLoadingView(message: 'Resolviendo QR...'),
      ),
    );
  }
}

class _QrScannerScreen extends StatefulWidget {
  const _QrScannerScreen();

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  final TextEditingController _manualController = TextEditingController();
  MobileScannerController? _scannerController;
  bool _didFinishScan = false;

  bool get _supportsLiveScanner {
    if (kIsWeb) {
      return true;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  @override
  void initState() {
    super.initState();

    if (_supportsLiveScanner) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
      );
    }
  }

  @override
  void dispose() {
    _manualController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _finishWithValue(String value) {
    if (_didFinishScan || value.trim().isEmpty) {
      return;
    }

    _didFinishScan = true;
    Navigator.of(context).pop(value.trim());
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_didFinishScan) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        _finishWithValue(rawValue);
        return;
      }
    }
  }

  Future<void> _submitManualValue() async {
    final rawValue = _manualController.text.trim();
    if (rawValue.isEmpty) {
      return;
    }

    _finishWithValue(rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            SectionCard(
              title: 'Reserva por QR',
              subtitle:
                  'Escaneá el código de una sala o un equipo para abrir directamente su reserva.',
              child: Text(
                _supportsLiveScanner
                    ? 'Alineá el QR dentro del marco. Si preferís, también podés pegar la URL o el UUID manualmente.'
                    : 'En esta plataforma no hay escaneo por cámara disponible, pero podés pegar la URL o el UUID del QR manualmente.',
              ),
            ),
            const SizedBox(height: 16),
            if (_supportsLiveScanner)
              Container(
                height: 340,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _handleDetect,
                    ),
                    IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const FanEmptyState(
                title: 'Escaneo por cámara no disponible',
                message:
                    'Podés seguir usando el flujo QR pegando manualmente la URL o el UUID del recurso.',
              ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Ingreso manual',
              subtitle: 'Acepta tanto la URL completa del QR como el UUID.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(
                    controller: _manualController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'URL o UUID del QR',
                      hintText:
                          'https://.../api/bookable-resource/qr/... o 7d54f6b7-...',
                      alignLabelWithHint: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitManualValue(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _submitManualValue,
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Usar este QR'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
