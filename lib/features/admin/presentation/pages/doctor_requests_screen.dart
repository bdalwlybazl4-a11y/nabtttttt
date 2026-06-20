import 'package:digl/features/admin/models/admin_models.dart';
import 'package:digl/features/admin/presentation/pages/doctor_request_details_screen.dart';
import 'package:digl/features/admin/services/admin_service.dart';
import 'package:flutter/material.dart';

class DoctorRequestsScreen extends StatefulWidget {
  const DoctorRequestsScreen({super.key});

  @override
  State<DoctorRequestsScreen> createState() => _DoctorRequestsScreenState();
}

class _DoctorRequestsScreenState extends State<DoctorRequestsScreen> {
  String _selectedFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<DoctorRequest>>(
              stream: AdminService.watchDoctorRequests(
                status: _selectedFilter == 'all' ? null : _selectedFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        const Text('حدث خطأ في تحميل البيانات'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) => _buildRequestCard(requests[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterButton('قيد الانتظار', 'pending', Icons.pending_actions_rounded),
            const SizedBox(width: 8),
            _buildFilterButton('موافق عليها', 'approved', Icons.verified_rounded),
            const SizedBox(width: 8),
            _buildFilterButton('مرفوضة', 'rejected', Icons.cancel_rounded),
            const SizedBox(width: 8),
            _buildFilterButton('الكل', 'all', Icons.list_alt_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      avatar: Icon(icon, size: 16, color: isSelected ? colorScheme.onPrimary : colorScheme.primary),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;

        });
      },
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primary,
      checkmarkColor: colorScheme.onPrimary,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
      ),
    );
  }

  Widget _buildRequestCard(DoctorRequest request) {
    final statusMeta = _statusMeta(request.status);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (statusMeta.color).withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: (statusMeta.color).withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DoctorRequestDetailsScreen(request: request)),
          );

          if (mounted) {
            setState(() {});
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: statusMeta.color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.medical_information_rounded, color: statusMeta.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.specialty.isEmpty ? 'تخصص غير محدد' : request.specialty,
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13.5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusMeta.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusMeta.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.schedule_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDate(request.createdAt),
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.65),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded, size: 74, color: Colors.grey[400]),
              const SizedBox(height: 14),
              Text(
                'لا توجد طلبات ${_getFilterLabel()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'سيتم عرض الطلبات هنا فور وصولها.',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusMeta _statusMeta(String status) {
    switch (status) {
      case 'pending':
        return const _StatusMeta(label: 'قيد الانتظار', color: Color(0xFFFFA62B));
      case 'approved':
        return const _StatusMeta(label: 'موافق عليها', color: Color(0xFF2CB67D));
      case 'rejected':
        return const _StatusMeta(label: 'مرفوضة', color: Color(0xFFE63946));
      default:
        return const _StatusMeta(label: 'غير معروف', color: Colors.grey);
    }
  }

  String _getFilterLabel() {
    switch (_selectedFilter) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'الموافق عليها';
      case 'rejected':
        return 'المرفوضة';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'قبل ${difference.inMinutes} دقيقة';
      }
      return 'قبل ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'قبل ${difference.inDays} أيام';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatusMeta {
  final String label;
  final Color color;

  const _StatusMeta({required this.label, required this.color});
}