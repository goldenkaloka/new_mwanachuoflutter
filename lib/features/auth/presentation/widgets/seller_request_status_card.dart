import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_event.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';

class SellerRequestStatusCard extends StatelessWidget {
  const SellerRequestStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Dispatch event to load status
    context.read<AuthBloc>().add(const GetSellerRequestStatusEvent());

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 2)),
          );
        }

        if (state is! SellerRequestStatusLoaded || state.status == null) {
          return const SizedBox.shrink();
        }

        final requestStatus = state.status;

        Color statusColor;
        IconData statusIcon;
        String statusText;

        switch (requestStatus) {
          case 'pending':
            statusColor = Colors.orange;
            statusIcon = Icons.hourglass_empty;
            statusText = 'Your seller request is being reviewed...';
            break;
          case 'approved':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            statusText = 'Congratulations! You\'re now a seller!';
            break;
          case 'rejected':
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
            statusText = 'Your seller request was rejected';
            break;
          default:
            return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

