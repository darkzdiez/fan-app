import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import 'reservations_models.dart';
import 'reservations_repository.dart';

class BookableModuleScreen extends StatelessWidget {
  const BookableModuleScreen({required this.type, super.key});

  final BookableResourceType type;

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).currentUser!;

    if (!user.userCan(type.info.viewPermission) &&
        !user.userCan(type.info.reservePermission) &&
        !user.userCan(type.info.calendarPermission)) {
      return FanEmptyState(
        title: 'Sin acceso al módulo',
        message:
            'Tu usuario no tiene permisos suficientes para ver ${type.info.title.toLowerCase()}.',
      );
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              tabs: <Widget>[
                Tab(text: type.info.resourcesTabLabel),
                const Tab(text: 'Reservas'),
                const Tab(text: 'Calendario'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _ResourcesTab(type: type),
                _ReservationsTab(type: type),
                _CalendarTab(type: type),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourcesTab extends StatefulWidget {
  const _ResourcesTab({required this.type});

  final BookableResourceType type;

  @override
  State<_ResourcesTab> createState() => _ResourcesTabState();
}

class _ResourcesTabState extends State<_ResourcesTab> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<BookableResource> _resources = const <BookableResource>[];

  ReservationsRepository get _repository =>
      ReservationsRepository(AppScope.of(context).apiClient);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadResources());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resources = await _repository.listResources(
        widget.type,
        search: _searchController.text,
      );

      setState(() {
        _resources = resources;
      });
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = collapseApiException(error);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'No se pudo cargar el listado.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openReservation(BookableResource resource) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _ReservationDialog(type: widget.type, resource: resource),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva creada correctamente.')),
      );
    }
  }

  Future<void> _openDetail(BookableResource resource) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _ResourceDetailSheet(type: widget.type, resource: resource),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return FanLoadingView(
        message: 'Cargando ${widget.type.info.title.toLowerCase()}...',
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          FanErrorBanner(message: _errorMessage!),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadResources,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadResources,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SectionCard(
            title: widget.type.info.title,
            subtitle:
                'Listado consumido desde ${widget.type.info.resourcePath}.',
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar por nombre',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _loadResources,
                    ),
                  ),
                  onSubmitted: (_) => _loadResources(),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Resultados: ${_resources.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          if (_resources.isEmpty)
            FanEmptyState(
              title: 'Sin resultados',
              message: 'No hay recursos disponibles para mostrar.',
            )
          else
            ..._resources.map(
              (resource) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        resource.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        resource.description.isEmpty
                            ? 'Sin descripción cargada.'
                            : resource.description,
                      ),
                      if (resource.fileUrl != null &&
                          resource.fileUrl!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        SelectableText('Archivo: ${resource.fileUrl}'),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: () => _openDetail(resource),
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Detalle'),
                          ),
                          FilledButton.icon(
                            onPressed: () => _openReservation(resource),
                            icon: const Icon(Icons.event_available),
                            label: const Text('Reservar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ReservationsTab extends StatefulWidget {
  const _ReservationsTab({required this.type});

  final BookableResourceType type;

  @override
  State<_ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<_ReservationsTab> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ReservationSummary> _reservations = const <ReservationSummary>[];

  ReservationsRepository get _repository =>
      ReservationsRepository(AppScope.of(context).apiClient);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReservations());
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reservations = await _repository.fetchMyReservations(widget.type);
      setState(() {
        _reservations = reservations;
      });
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = collapseApiException(error);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'No se pudo cargar el historial de reservas.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelReservation(ReservationSummary reservation) async {
    final cancelled = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _CancelReservationDialog(type: widget.type, reservation: reservation),
    );

    if (cancelled == true) {
      await _loadReservations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada correctamente.')),
        );
      }
    }
  }

  Future<void> _rateReservation(ReservationSummary reservation) async {
    final rated = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _RateReservationDialog(type: widget.type, reservation: reservation),
    );

    if (rated == true) {
      await _loadReservations();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const FanLoadingView(message: 'Cargando mis reservas...');
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          FanErrorBanner(message: _errorMessage!),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadReservations,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SectionCard(
            title: 'Mis reservas',
            subtitle:
                'El backend devuelve reservas activas, canceladas y soft-deleted.',
            child: Text(
              'Total cargado: ${_reservations.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (_reservations.isEmpty)
            const FanEmptyState(
              title: 'Sin reservas',
              message: 'Todavía no tenés reservas registradas.',
            )
          else
            ..._reservations.map(
              (reservation) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              reservation.resourceName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (reservation.isCancelled)
                            Chip(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              labelStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                              label: const Text('Cancelada'),
                            ),
                          if (!reservation.isCancelled &&
                              reservation.userRating != null)
                            Chip(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              labelStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                              label: Text(
                                'Calificada ${reservation.userRating}/5',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Fecha: ${formatHumanDate(reservation.date)}'),
                      Text(
                        'Horario: ${reservation.startTime} - ${reservation.endTime}',
                      ),
                      if (reservation.organizationName != null)
                        Text('Organización: ${reservation.organizationName}'),
                      if (reservation.cancellationReason != null &&
                          reservation
                              .cancellationReason!
                              .isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          'Motivo de cancelación: ${reservation.cancellationReason}',
                        ),
                      ],
                      if (reservation.userObservations != null &&
                          reservation.userObservations!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Text('Observaciones: ${reservation.userObservations}'),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          if (!reservation.isCancelled &&
                              isReservationInFuture(
                                reservation.date,
                                reservation.startTime,
                              ))
                            OutlinedButton.icon(
                              onPressed: () => _cancelReservation(reservation),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancelar'),
                            ),
                          if (!reservation.isCancelled &&
                              reservation.userRating == null &&
                              isReservationInPast(
                                reservation.date,
                                reservation.endTime,
                              ))
                            FilledButton.tonalIcon(
                              onPressed: () => _rateReservation(reservation),
                              icon: const Icon(Icons.star_outline),
                              label: const Text('Calificar'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CalendarTab extends StatefulWidget {
  const _CalendarTab({required this.type});

  final BookableResourceType type;

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int? _selectedResourceId;
  bool _isLoading = true;
  String? _errorMessage;
  List<BookableResource> _resources = const <BookableResource>[];
  ReservationCalendarResponse? _calendar;

  ReservationsRepository get _repository =>
      ReservationsRepository(AppScope.of(context).apiClient);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCalendar());
  }

  Future<void> _loadCalendar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resources = await _repository.listResources(widget.type);
      final calendar = await _repository.fetchCalendar(
        widget.type,
        ym: formatMonthKey(_visibleMonth),
        resourceId: _selectedResourceId,
      );

      setState(() {
        _resources = resources;
        _calendar = calendar;
      });
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = collapseApiException(error);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'No se pudo cargar el calendario.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
    _loadCalendar();
  }

  void _openDay(CalendarDay day) {
    if (day.reservations.isEmpty) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                'Reservas del ${formatHumanDate(day.date)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...day.reservations.map(
                (reservation) => Card(
                  child: ListTile(
                    title: Text(reservation.title),
                    subtitle: Text(
                      '${reservation.startTime} - ${reservation.endTime}\n${reservation.organizationName}',
                    ),
                    isThreeLine: true,
                    trailing: Text(reservation.status),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const FanLoadingView(message: 'Cargando calendario...');
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          FanErrorBanner(message: _errorMessage!),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadCalendar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    final calendar = _calendar;
    if (calendar == null) {
      return const FanEmptyState(
        title: 'Sin calendario',
        message: 'No se pudo obtener la estructura mensual.',
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompactCalendar = screenWidth < 640;
    final isTightCalendar = screenWidth < 390;
    final weekdayLabels = isCompactCalendar
        ? const <String>['L', 'M', 'X', 'J', 'V', 'S', 'D']
        : const <String>['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    return RefreshIndicator(
      onRefresh: _loadCalendar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SectionCard(
            title: 'Calendario',
            subtitle: 'Vista mensual generada por la API de reservas.',
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        calendar.meta.title.isNotEmpty
                            ? calendar.meta.title
                            : formatMonthLabel(_visibleMonth),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: _selectedResourceId,
                  decoration: InputDecoration(
                    labelText: isTightCalendar
                        ? 'Recurso'
                        : 'Filtrar por recurso (opcional)',
                  ),
                  items: <DropdownMenuItem<int?>>[
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ..._resources.map(
                      (resource) => DropdownMenuItem<int?>(
                        value: resource.id,
                        child: Text(
                          resource.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedResourceId = value;
                    });
                    _loadCalendar();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(isCompactCalendar ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: weekdayLabels
                      .map(
                        (label) => _WeekdayHeader(
                          label: label,
                          compact: isCompactCalendar,
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: isCompactCalendar ? 6 : 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: calendar.days.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: isCompactCalendar ? 4 : 8,
                    crossAxisSpacing: isCompactCalendar ? 4 : 8,
                    childAspectRatio: isCompactCalendar
                        ? (isTightCalendar ? 0.78 : 0.92)
                        : 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final day = calendar.days[index];
                    return _CalendarDayTile(
                      day: day,
                      compact: isCompactCalendar,
                      tight: isTightCalendar,
                      onTap: day.reservations.isEmpty
                          ? null
                          : () => _openDay(day),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: compact ? 1 : 2),
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
        decoration: BoxDecoration(
          color: compact ? const Color(0xFFF1F5F8) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: compact ? 11 : null,
          ),
        ),
      ),
    );
  }
}

class _CalendarDayTile extends StatelessWidget {
  const _CalendarDayTile({
    required this.day,
    required this.compact,
    required this.tight,
    this.onTap,
  });

  final CalendarDay day;
  final bool compact;
  final bool tight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reservationCount = day.reservations.length;
    final baseColor = day.inCurrentMonth ? Colors.white : Colors.grey.shade100;
    final borderColor = day.isToday ? scheme.primary : Colors.grey.shade300;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(compact ? 14 : 12),
      child: Container(
        padding: EdgeInsets.all(compact ? (tight ? 4 : 6) : 8),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(compact ? 14 : 12),
          border: Border.all(color: borderColor),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        '${day.dayNumber}',
                        style:
                            (tight
                                    ? theme.textTheme.labelMedium
                                    : theme.textTheme.labelLarge)
                                ?.copyWith(
                                  fontWeight: day.isToday
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: day.inCurrentMonth
                                      ? scheme.onSurface
                                      : scheme.onSurface.withValues(
                                          alpha: 0.46,
                                        ),
                                ),
                      ),
                      const Spacer(),
                      if (day.isToday)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (reservationCount > 0)
                    tight
                        ? Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$reservationCount',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Expanded(
                                child: Wrap(
                                  spacing: 3,
                                  runSpacing: 3,
                                  children: <Widget>[
                                    ...day.reservations
                                        .take(3)
                                        .map(
                                          (_) => Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: scheme.primary,
                                            ),
                                          ),
                                        ),
                                    if (reservationCount > 3)
                                      Text(
                                        '+${reservationCount - 3}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: scheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$reservationCount',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${day.dayNumber}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: day.isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: reservationCount == 0
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: day.reservations
                                .take(2)
                                .map(
                                  (reservation) => Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: scheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      reservation.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  if (reservationCount > 2)
                    Text(
                      '+${reservationCount - 2} más',
                      style: theme.textTheme.labelSmall,
                    ),
                ],
              ),
      ),
    );
  }
}

class _ResourceDetailSheet extends StatelessWidget {
  const _ResourceDetailSheet({required this.type, required this.resource});

  final BookableResourceType type;
  final BookableResource resource;

  @override
  Widget build(BuildContext context) {
    final repository = ReservationsRepository(AppScope.of(context).apiClient);

    return SafeArea(
      child: FutureBuilder<ResourceDetail>(
        future: repository.fetchResourceDetail(type, resource.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 260,
              child: FanLoadingView(message: 'Cargando detalle...'),
            );
          }

          if (snapshot.hasError) {
            return SizedBox(
              height: 260,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No se pudo cargar el detalle del recurso.'),
                ),
              ),
            );
          }

          final detail = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                detail.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                detail.description.isEmpty
                    ? 'Sin descripción cargada.'
                    : detail.description,
              ),
              if (detail.fileUrl != null &&
                  detail.fileUrl!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                SelectableText('Archivo: ${detail.fileUrl}'),
              ],
              const SizedBox(height: 16),
              Text(
                'Historial del recurso',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (detail.reservations.isEmpty)
                const Text('No hay reservas cargadas para este recurso.')
              else
                ...detail.reservations.map(
                  (reservation) => Card(
                    child: ListTile(
                      title: Text(formatHumanDate(reservation.date)),
                      subtitle: Text(
                        '${reservation.startTime} - ${reservation.endTime}\n${reservation.organizationName ?? 'Sin organización'}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReservationDialog extends StatefulWidget {
  const _ReservationDialog({required this.type, required this.resource});

  final BookableResourceType type;
  final BookableResource resource;

  @override
  State<_ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<_ReservationDialog> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedStartTime;
  String? _selectedEndTime;
  bool _isLoadingAvailability = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  ReservationAvailability? _availability;

  ReservationsRepository get _repository =>
      ReservationsRepository(AppScope.of(context).apiClient);

  AppControllerData get _app => AppControllerData(AppScope.of(context));

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
    startTime: _app.reservationConfig.startTime,
    endTime: _app.reservationConfig.endTime,
    intervalMinutes: _app.reservationConfig.intervalMinutes,
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
                  'Como incubada, para salas reservás un bloque fijo de ${_app.reservationConfig.intervalMinutes} minutos.',
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

class _CancelReservationDialog extends StatefulWidget {
  const _CancelReservationDialog({
    required this.type,
    required this.reservation,
  });

  final BookableResourceType type;
  final ReservationSummary reservation;

  @override
  State<_CancelReservationDialog> createState() =>
      _CancelReservationDialogState();
}

class _CancelReservationDialogState extends State<_CancelReservationDialog> {
  static const List<String> _suggestedReasons = <String>[
    'Cambio de agenda',
    'Ya no voy a utilizar el recurso',
    'Reserva duplicada',
    'La actividad fue reprogramada',
  ];

  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _selectedSuggestedReason;

  ReservationsRepository get _repository =>
      ReservationsRepository(AppScope.of(context).apiClient);

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _applySuggestedReason(String reason) {
    _reasonController
      ..text = reason
      ..selection = TextSelection.collapsed(offset: reason.length);

    setState(() {
      _selectedSuggestedReason = reason;
      _errorMessage = null;
    });
  }

  void _handleReasonChanged(String value) {
    if (_errorMessage == null && _selectedSuggestedReason == value.trim()) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _selectedSuggestedReason = _suggestedReasons.contains(value.trim())
          ? value.trim()
          : null;
    });
  }

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Ingresá un motivo de cancelación.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _repository.cancelReservation(
        widget.type,
        reservationId: widget.reservation.id,
        reason: _reasonController.text.trim(),
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
        _errorMessage = 'No se pudo cancelar la reserva.';
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
      title: const Text('Cancelar reserva'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                widget.reservation.resourceName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('Fecha: ${formatHumanDate(widget.reservation.date)}'),
              Text(
                'Horario: ${widget.reservation.startTime} - ${widget.reservation.endTime}',
              ),
              const SizedBox(height: 12),
              const Text(
                'Podés usar un motivo sugerido o escribir uno personalizado.',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedSuggestedReason,
                decoration: const InputDecoration(labelText: 'Motivo sugerido'),
                items: _suggestedReasons
                    .map(
                      (reason) => DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        _applySuggestedReason(value);
                      },
              ),
              const SizedBox(height: 12),
              Semantics(
                container: true,
                textField: true,
                multiline: true,
                label: 'Motivo de cancelación',
                child: TextField(
                  controller: _reasonController,
                  minLines: 2,
                  maxLines: 4,
                  onChanged: _handleReasonChanged,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de cancelación',
                    helperText:
                        'Podés editar el motivo sugerido antes de confirmar.',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
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
          child: const Text('Cerrar'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: Text(_isSubmitting ? 'Enviando...' : 'Confirmar'),
        ),
      ],
    );
  }
}

class _RateReservationDialog extends StatefulWidget {
  const _RateReservationDialog({required this.type, required this.reservation});

  final BookableResourceType type;
  final ReservationSummary reservation;

  @override
  State<_RateReservationDialog> createState() => _RateReservationDialogState();
}

class _RateReservationDialogState extends State<_RateReservationDialog> {
  final TextEditingController _observationsController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false;
  String? _errorMessage;

  ReservationsRepository get _repository =>
      ReservationsRepository(AppScope.of(context).apiClient);

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _repository.rateReservation(
        widget.type,
        reservationId: widget.reservation.id,
        rating: _selectedRating,
        observations: _observationsController.text.trim(),
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
        _errorMessage = 'No se pudo calificar la reserva.';
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
      title: const Text('Calificar reserva'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(
              5,
              (index) => ChoiceChip(
                label: Text('${index + 1}★'),
                selected: _selectedRating == index + 1,
                onSelected: (_) {
                  setState(() {
                    _selectedRating = index + 1;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _observationsController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Observaciones (opcional)',
            ),
          ),
          if (_errorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            FanErrorBanner(message: _errorMessage!),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cerrar'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: Text(_isSubmitting ? 'Enviando...' : 'Enviar calificación'),
        ),
      ],
    );
  }
}

/// Wrapper mínimo para no pasar todo el controller a cada helper.
class AppControllerData {
  AppControllerData(this.controller);

  final dynamic controller;

  ReservationConfig get reservationConfig =>
      controller.reservationConfig as ReservationConfig;
}
