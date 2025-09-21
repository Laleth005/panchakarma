import 'package:flutter/material.dart';
import '../models/therapy_session_model.dart';
import '../services/practitioner_repository.dart';
import 'package:intl/intl.dart';

class TodaySchedulePanel extends StatefulWidget {
  final String practitionerId;
  final Function(TherapySessionModel) onSessionTap;
  final Function(TherapySessionModel, SessionStatus) onStatusChange;
  final Function(bool isRefreshing) onLoadingStateChanged;

  const TodaySchedulePanel({
    Key? key,
    required this.practitionerId,
    required this.onSessionTap,
    required this.onStatusChange,
    required this.onLoadingStateChanged,
  }) : super(key: key);

  @override
  _TodaySchedulePanelState createState() => _TodaySchedulePanelState();
}

class _TodaySchedulePanelState extends State<TodaySchedulePanel> {
  final PractitionerRepository _repository = PractitionerRepository();
  List<TherapySessionModel> _sessions = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    widget.onLoadingStateChanged(true);

    try {
      final sessions = await _repository.getTodaySessions(
        widget.practitionerId,
      );
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }

    widget.onLoadingStateChanged(false);
  }

  Future<void> _updateSessionStatus(
    TherapySessionModel session,
    SessionStatus newStatus,
  ) async {
    final success = await _repository.updateSessionStatus(
      session.id,
      newStatus,
    );

    if (success) {
      setState(() {
        final index = _sessions.indexWhere((s) => s.id == session.id);
        if (index != -1) {
          _sessions[index] = session.copyWith(status: newStatus);
        }
      });

      widget.onStatusChange(session, newStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Schedule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.green),
                  onPressed: _loadSessions,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          Divider(height: 1),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasError)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Error loading schedule',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    TextButton(onPressed: _loadSessions, child: Text('Retry')),
                  ],
                ),
              ),
            )
          else if (_sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No sessions scheduled for today',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _sessions.length,
                padding: EdgeInsets.symmetric(vertical: 8),
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  return _buildSessionItem(session);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(TherapySessionModel session) {
    return InkWell(
      onTap: () => widget.onSessionTap(session),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: session.status.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.patientName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('h:mm a').format(session.dateTime),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${session.therapyType} (${session.durationMinutes} min)',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                      Text(
                        'Room ${session.roomNumber}, Bed ${session.bedNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (session.hasSpecialInstructions)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.amber.shade800,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Special Instructions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: session.status.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            session.status.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: session.status.color,
                            ),
                          ),
                        ),
                      ),
                      if (session.status == SessionStatus.pending)
                        TextButton.icon(
                          icon: Icon(Icons.play_arrow, size: 16),
                          label: Text('Start'),
                          onPressed: () => _updateSessionStatus(
                            session,
                            SessionStatus.inProgress,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      if (session.status == SessionStatus.inProgress)
                        TextButton.icon(
                          icon: Icon(Icons.check_circle_outline, size: 16),
                          label: Text('Complete'),
                          onPressed: () => _updateSessionStatus(
                            session,
                            SessionStatus.completed,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
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
