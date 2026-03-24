import 'package:flutter/material.dart';

/// Consistent empty and error states with optional retry.
class EmptyErrorView extends StatelessWidget {
  final bool isError;
  final String message;
  final String? detail;
  final VoidCallback? onRetry;
  final IconData? icon;

  const EmptyErrorView({
    super.key,
    required this.isError,
    required this.message,
    this.detail,
    this.onRetry,
    this.icon,
  });

  factory EmptyErrorView.networkError({VoidCallback? onRetry}) {
    return EmptyErrorView(
      isError: true,
      message: 'No connection',
      detail: 'Check your network and try again.',
      onRetry: onRetry,
      icon: Icons.wifi_off,
    );
  }

  factory EmptyErrorView.serverError({VoidCallback? onRetry}) {
    return EmptyErrorView(
      isError: true,
      message: 'Something went wrong',
      detail: 'We couldn’t load this. Please try again.',
      onRetry: onRetry,
      icon: Icons.error_outline,
    );
  }

  factory EmptyErrorView.empty({
    required String message,
    String? detail,
    IconData? icon,
  }) {
    return EmptyErrorView(
      isError: false,
      message: message,
      detail: detail,
      icon: icon ?? Icons.inbox_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = isError ? Colors.red : Colors.grey;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? (isError ? Icons.error_outline : Icons.inbox_outlined),
              size: 64,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isError ? Colors.red : theme.textTheme.bodyLarge?.color,
              ),
            ),
            if (detail != null && detail!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
