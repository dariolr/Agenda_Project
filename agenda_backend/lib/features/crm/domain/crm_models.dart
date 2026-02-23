class CrmClientKpi {
  final int visitsCount;
  final double totalSpent;
  final double avgTicket;
  final DateTime? lastVisit;
  final int noShowCount;

  const CrmClientKpi({
    required this.visitsCount,
    required this.totalSpent,
    required this.avgTicket,
    required this.lastVisit,
    required this.noShowCount,
  });

  factory CrmClientKpi.fromJson(Map<String, dynamic> json) {
    return CrmClientKpi(
      visitsCount: (json['visits_count'] as num?)?.toInt() ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
      avgTicket: (json['avg_ticket'] as num?)?.toDouble() ?? 0,
      lastVisit: json['last_visit'] != null
          ? DateTime.tryParse(json['last_visit'] as String)
          : null,
      noShowCount: (json['no_show_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CrmClient {
  final int id;
  final int businessId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? city;
  final String status;
  final bool isArchived;
  final List<String> tags;
  final CrmClientKpi kpi;

  const CrmClient({
    required this.id,
    required this.businessId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.city,
    required this.status,
    required this.isArchived,
    required this.tags,
    required this.kpi,
  });

  String get fullName {
    final parts = <String>[];
    if ((firstName ?? '').trim().isNotEmpty) parts.add(firstName!.trim());
    if ((lastName ?? '').trim().isNotEmpty) parts.add(lastName!.trim());
    return parts.join(' ').trim();
  }

  factory CrmClient.fromJson(Map<String, dynamic> json) {
    return CrmClient(
      id: (json['id'] as num).toInt(),
      businessId: (json['business_id'] as num).toInt(),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      status: (json['status'] as String?) ?? 'active',
      isArchived: json['is_archived'] as bool? ?? false,
      tags: ((json['tags'] as List?) ?? const []).whereType<String>().toList(),
      kpi: CrmClientKpi.fromJson((json['kpi'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }
}

class CrmTag {
  final int id;
  final String name;
  final String? color;

  const CrmTag({required this.id, required this.name, this.color});

  factory CrmTag.fromJson(Map<String, dynamic> json) => CrmTag(
        id: (json['id'] as num).toInt(),
        name: (json['name'] as String?) ?? '',
        color: json['color'] as String?,
      );
}

class CrmTask {
  final int id;
  final int clientId;
  final String title;
  final String status;
  final String priority;
  final DateTime? dueAt;
  final bool isOverdue;

  const CrmTask({
    required this.id,
    required this.clientId,
    required this.title,
    required this.status,
    required this.priority,
    required this.dueAt,
    required this.isOverdue,
  });

  factory CrmTask.fromJson(Map<String, dynamic> json) => CrmTask(
        id: (json['id'] as num).toInt(),
        clientId: (json['client_id'] as num).toInt(),
        title: (json['title'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'open',
        priority: (json['priority'] as String?) ?? 'medium',
        dueAt: json['due_at'] != null ? DateTime.tryParse(json['due_at'] as String) : null,
        isOverdue: json['is_overdue'] as bool? ?? false,
      );
}

class CrmEvent {
  final int id;
  final String eventType;
  final Map<String, dynamic>? payload;
  final DateTime? occurredAt;

  const CrmEvent({
    required this.id,
    required this.eventType,
    required this.payload,
    required this.occurredAt,
  });

  factory CrmEvent.fromJson(Map<String, dynamic> json) => CrmEvent(
        id: (json['id'] as num).toInt(),
        eventType: (json['event_type'] as String?) ?? '',
        payload: (json['payload'] as Map?)?.cast<String, dynamic>(),
        occurredAt: json['occurred_at'] != null ? DateTime.tryParse(json['occurred_at'] as String) : null,
      );
}

class CrmSegment {
  final int id;
  final String name;
  final Map<String, dynamic> filters;

  const CrmSegment({required this.id, required this.name, required this.filters});

  factory CrmSegment.fromJson(Map<String, dynamic> json) => CrmSegment(
        id: (json['id'] as num).toInt(),
        name: (json['name'] as String?) ?? '',
        filters: (json['filters'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

class CrmClientsPage {
  final List<CrmClient> clients;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const CrmClientsPage({
    required this.clients,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });
}
