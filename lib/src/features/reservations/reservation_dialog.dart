import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import 'reservations_models.dart';
import 'reservations_repository.dart';

class ReservationDialog extends StatefulWidget {
  const ReservationDialog({
    required this.type,
    required this.resource,
    super.key,
  });

  final BookableResourceType type;
  final BookableResource resource;

  @override
  State<ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<ReservationDialog> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedStartTime;
  String? _selectedEndTime;
  bool _isLoadingAvailability = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  ReservationAvailability? _availability;

  ReservationsRepository get _repository =>
      ReservationsRepository(AppScope.of(context).apiClient);

  ReservationConfig get _reservationConfig =>
      AppScope.of(context).reservationConfig;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAvailability());
  }

  bool get _useSingleSlot {
    final user = AppScope.of(context).currentUser;
    return (user?.isIncubada ?? false) &&
        widget.type.info.usesSingleSlotForIncubada;
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es'),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedDate = selected;
      _selectedStartTime = null;
      _selectedEndTime = null;
    });

    await _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoadingAvailability = true;
      _errorMessage = null;
    });

    try {
      final availability = await _repository.fetchAvailability(
        widget.type,
        date: formatApiDate(_selectedDate),
        resourceId: widget.resource.id,
      );

      setState(() {
        _availability = availability;
      });
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = collapseApiException(error);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'No se pudo consultar la disponibilidad.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAvailability = false;
        });
      }
    }
  }

  List<String> get _allBoundaries => generateTimeSlots(
    startTime: _reservationConfig.startTime,
    endTime: _reservationConfig.endTime,
    intervalMinutes: _reservationConfig.intervalMinutes,
    includeEnd: true,
  );

  List<String> get _startOptions {
    final blocked = <String>{
      ...?_availability?.reservedHours,
      ...?_availability?.disabledHours,
    };

    final allStarts = _allBoundaries.length > 1
        ? _allBoundaries.sublist(0, _allBoundaries.length - 1)
        : const <String>[];

    return allStarts.where((slot) => !blocked.contains(slot)).toList();
  }

  List<String> get _endOptions {
    if (_selectedStartTime == null) {
      return const <String>[];
    }

    final index = _allBoundaries.indexOf(_selectedStartTime!);
    if (index == -1) {
      return const <String>[];
    }

    return _allBoundaries.sublist(index + 1);
  }

  Future<void> _submit() async {
    if (_selectedStartTime == null) {
      setState(() {
        _errorMessage = 'Seleccioná una hora de inicio.';
      });
      return;
    }

    if (!_useSingleSlot && _selectedEndTime == null) {
      setState(() {
        _errorMessage = 'Seleccioná una hora de finalización.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _repository.createReservation(
        widget.type,
        date: formatApiDate(_selectedDate),
        startTime: _selectedStartTime!,
        endTime: _useSingleSlot ? null : _selectedEndTime,
        resourceId: widget.resource.id,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = collapseApiException(error);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'No se pudo crear la reserva.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reservar ${widget.resource.name}'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  'Fecha: ${formatHumanDate(formatApiDate(_selectedDate))}',
                ),
              ),
              const SizedBox(height: 12),
              if (_useSingleSlot)
                Text(
                  'Como incubada, para salas reservás un bloque fijo de ${_reservationConfig.intervalMinutes} minutos.',
                )
              else
                const Text(
                  'Seleccioná una hora de inicio y otra de fin. El backend valida solapamientos y reglas del recurso.',
                ),
              const SizedBox(height: 12),
              if (_isLoadingAvailability)
                const FanLoadingView(message: 'Consultando disponibilidad...')
              else ...<Widget>[
                DropdownButtonFormField<String>(
                  initialValue: _startOptions.contains(_selectedStartTime)
                      ? _selectedStartTime
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Hora de inicio',
                  ),
                  items: _startOptions
                      .map(
                        (slot) => DropdownMenuItem<String>(
                          value: slot,
                          child: Text(slot),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStartTime = value;
                      if (!_endOptions.contains(_selectedEndTime)) {
                        _selectedEndTime = null;
                      }
                    });
                  },
                ),
                if (!_useSingleSlot) ...<Widget>[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _endOptions.contains(_selectedEndTime)
                        ? _selectedEndTime
                        : null,
                    decoration: const InputDecoration(labelText: 'Hora de fin'),
                    items: _endOptions
                        .map(
                          (slot) => DropdownMenuItem<String>(
                            value: slot,
                            child: Text(slot),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEndTime = value;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Slots reservados: ${_availability?.reservedHours.join(', ') ?? 'sin datos'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Slots deshabilitados: ${_availability?.disabledHours.join(', ') ?? 'sin datos'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 12),
                FanErrorBanner(message: _errorMessage!),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: Text(_isSubmitting ? 'Reservando...' : 'Confirmar'),
        ),
      ],
    );
  }
}
