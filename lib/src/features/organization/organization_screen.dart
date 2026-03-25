import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import 'organization_repository.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key});

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _registrationDateController =
      TextEditingController();
  final TextEditingController _incubatorController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _alarmCodeController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _artValidFromController = TextEditingController();
  final TextEditingController _artValidToController = TextEditingController();
  final TextEditingController _coverageValidFromController =
      TextEditingController();
  final TextEditingController _coverageValidToController =
      TextEditingController();

  bool _hasNonRepetitionClause = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  String? _logoUrl;
  String? _equipmentConsentUrl;
  String? _contractUrl;
  String? _artPolicyUrl;
  String? _coverageCertificateUrl;

  SelectedFile? _logoFile;
  SelectedFile? _equipmentConsentFile;
  SelectedFile? _contractFile;
  SelectedFile? _artPolicyFile;
  SelectedFile? _coverageCertificateFile;

  OrganizationRepository get _repository =>
      OrganizationRepository(AppScope.of(context).apiClient);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrganization());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _registrationDateController.dispose();
    _incubatorController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _alarmCodeController.dispose();
    _statusController.dispose();
    _artValidFromController.dispose();
    _artValidToController.dispose();
    _coverageValidFromController.dispose();
    _coverageValidToController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganization() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final organization = await _repository.fetchOrganization();
      _applyOrganization(organization);
    } on ApiException catch (error) {
      _errorMessage = collapseApiException(error);
    } catch (_) {
      _errorMessage = 'No se pudo cargar la información de la incubada.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyOrganization(OrganizationProfile organization) {
    _nameController.text = organization.name;
    _registrationDateController.text = organization.registrationDate;
    _incubatorController.text = organization.incubator;
    _contactPersonController.text = organization.contactPerson;
    _phoneController.text = organization.phone;
    _emailController.text = organization.email;
    _alarmCodeController.text = organization.alarmCode;
    _statusController.text = organization.status;
    _artValidFromController.text = organization.artValidFrom;
    _artValidToController.text = organization.artValidTo;
    _coverageValidFromController.text = organization.coverageValidFrom;
    _coverageValidToController.text = organization.coverageValidTo;
    _hasNonRepetitionClause = organization.hasNonRepetitionClause;

    _logoUrl = organization.logoUrl;
    _equipmentConsentUrl = organization.equipmentConsentUrl;
    _contractUrl = organization.contractUrl;
    _artPolicyUrl = organization.artPolicyUrl;
    _coverageCertificateUrl = organization.coverageCertificateUrl;

    _logoFile = null;
    _equipmentConsentFile = null;
    _contractFile = null;
    _artPolicyFile = null;
    _coverageCertificateFile = null;
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final current = controller.text.isNotEmpty
        ? DateTime.tryParse(controller.text)
        : DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es'),
    );

    if (date != null) {
      controller.text = formatApiDate(date);
    }
  }

  Future<void> _pickFile({
    required bool imageOnly,
    required ValueChanged<SelectedFile?> onSelected,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: imageOnly ? FileType.image : FileType.any,
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    onSelected(
      SelectedFile(fileName: file.name, path: file.path, bytes: file.bytes),
    );
  }

  Future<void> _saveOrganization() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final saved = await _repository.saveOrganization(
        fields: <String, String>{
          'name': _incubatorController.text.trim().isNotEmpty
              ? _incubatorController.text.trim()
              : (_nameController.text.trim().isNotEmpty
                    ? _nameController.text.trim()
                    : 'Sin Nombre'),
          'registration_date': _registrationDateController.text.trim(),
          'incubator': _incubatorController.text.trim(),
          'contact_person': _contactPersonController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'alarm_code': _alarmCodeController.text.trim(),
          'status': _statusController.text.trim(),
          'art_valid_from': _artValidFromController.text.trim(),
          'art_valid_to': _artValidToController.text.trim(),
          'coverage_valid_from': _coverageValidFromController.text.trim(),
          'coverage_valid_to': _coverageValidToController.text.trim(),
          'has_non_repetition_clause': _hasNonRepetitionClause ? '1' : '0',
        },
        files: <ApiFilePart>[
          if (_logoFile != null)
            ApiFilePart(fieldName: 'logo', file: _logoFile!),
          if (_equipmentConsentFile != null)
            ApiFilePart(
              fieldName: 'equipment_consent',
              file: _equipmentConsentFile!,
            ),
          if (_contractFile != null)
            ApiFilePart(fieldName: 'contract', file: _contractFile!),
          if (_artPolicyFile != null)
            ApiFilePart(fieldName: 'art_policy', file: _artPolicyFile!),
          if (_coverageCertificateFile != null)
            ApiFilePart(
              fieldName: 'coverage_certificate',
              file: _coverageCertificateFile!,
            ),
        ],
      );

      _applyOrganization(saved);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La incubada se guardó correctamente.')),
        );
      }
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = collapseApiException(error);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'No se pudo guardar la incubada.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _pickDate(controller),
        ),
      ),
    );
  }

  Widget _buildFilePicker({
    required String title,
    required SelectedFile? selectedFile,
    required String? currentUrl,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (currentUrl != null && currentUrl.isNotEmpty)
              SelectableText('Archivo actual: $currentUrl'),
            if (selectedFile != null)
              Text('Archivo seleccionado: ${selectedFile.fileName}'),
            if ((currentUrl == null || currentUrl.isEmpty) &&
                selectedFile == null)
              const Text('Todavía no hay archivo asociado.'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Seleccionar archivo'),
                ),
                if (selectedFile != null)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.close),
                    label: const Text('Quitar selección'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const FanLoadingView(message: 'Cargando incubada...');
    }

    return RefreshIndicator(
      onRefresh: _loadOrganization,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SectionCard(
            title: 'Datos principales',
            subtitle:
                'Edición de la organización autenticada vía `/api/incubada`.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre legal / visible',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _incubatorController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre incubada',
                    helperText:
                        'Si este valor existe, se usa también como `name` al guardar.',
                  ),
                ),
                const SizedBox(height: 12),
                _buildDateField(
                  label: 'Fecha de registro',
                  controller: _registrationDateController,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _statusController,
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _hasNonRepetitionClause,
                  onChanged: (value) {
                    setState(() {
                      _hasNonRepetitionClause = value;
                    });
                  },
                  title: const Text('Tiene cláusula de no repetición'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Contacto',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _contactPersonController,
                  decoration: const InputDecoration(
                    labelText: 'Persona de contacto',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _alarmCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de alarma',
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Coberturas y vigencias',
            child: Column(
              children: <Widget>[
                _buildDateField(
                  label: 'ART válida desde',
                  controller: _artValidFromController,
                ),
                const SizedBox(height: 12),
                _buildDateField(
                  label: 'ART válida hasta',
                  controller: _artValidToController,
                ),
                const SizedBox(height: 12),
                _buildDateField(
                  label: 'Cobertura válida desde',
                  controller: _coverageValidFromController,
                ),
                const SizedBox(height: 12),
                _buildDateField(
                  label: 'Cobertura válida hasta',
                  controller: _coverageValidToController,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Archivos adjuntos',
            subtitle:
                'Los uploads se envían por multipart como en la app web actual.',
            child: Column(
              children: <Widget>[
                _buildFilePicker(
                  title: 'Logo',
                  selectedFile: _logoFile,
                  currentUrl: _logoUrl,
                  onPick: () => _pickFile(
                    imageOnly: true,
                    onSelected: (file) => setState(() => _logoFile = file),
                  ),
                  onClear: () => setState(() => _logoFile = null),
                ),
                _buildFilePicker(
                  title: 'Consentimiento de equipos',
                  selectedFile: _equipmentConsentFile,
                  currentUrl: _equipmentConsentUrl,
                  onPick: () => _pickFile(
                    imageOnly: false,
                    onSelected: (file) =>
                        setState(() => _equipmentConsentFile = file),
                  ),
                  onClear: () => setState(() => _equipmentConsentFile = null),
                ),
                _buildFilePicker(
                  title: 'Contrato',
                  selectedFile: _contractFile,
                  currentUrl: _contractUrl,
                  onPick: () => _pickFile(
                    imageOnly: false,
                    onSelected: (file) => setState(() => _contractFile = file),
                  ),
                  onClear: () => setState(() => _contractFile = null),
                ),
                _buildFilePicker(
                  title: 'Póliza ART',
                  selectedFile: _artPolicyFile,
                  currentUrl: _artPolicyUrl,
                  onPick: () => _pickFile(
                    imageOnly: false,
                    onSelected: (file) => setState(() => _artPolicyFile = file),
                  ),
                  onClear: () => setState(() => _artPolicyFile = null),
                ),
                _buildFilePicker(
                  title: 'Certificado de cobertura',
                  selectedFile: _coverageCertificateFile,
                  currentUrl: _coverageCertificateUrl,
                  onPick: () => _pickFile(
                    imageOnly: false,
                    onSelected: (file) =>
                        setState(() => _coverageCertificateFile = file),
                  ),
                  onClear: () =>
                      setState(() => _coverageCertificateFile = null),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) FanErrorBanner(message: _errorMessage!),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveOrganization,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Guardando...' : 'Guardar incubada'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
