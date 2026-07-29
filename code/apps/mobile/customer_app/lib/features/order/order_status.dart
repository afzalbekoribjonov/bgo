import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Buyurtma holatini tilga mos matnga aylantiradi.
String orderStatusLabel(String status, AppLocalizations t) {
  switch (status) {
    case 'PENDING':
      return t.statusPending;
    case 'ACCEPTED':
      return t.statusAccepted;
    case 'PREPARING':
      return t.statusPreparing;
    case 'READY':
      return t.statusReady;
    case 'ASSIGNED':
    case 'IN_PROGRESS':
    case 'PICKED_UP':
      return t.statusOnTheWay;
    case 'DELIVERED':
    case 'COMPLETED':
      return t.statusDelivered;
    case 'CANCELLED':
      return t.statusCancelled;
    case 'FAILED':
      return t.statusFailed;
    default:
      return status;
  }
}

/// Holatga mos rang.
Color orderStatusColor(String status) {
  switch (status) {
    case 'PENDING':
      return Colors.orange;
    case 'CANCELLED':
    case 'FAILED':
      return Colors.red;
    case 'DELIVERED':
    case 'COMPLETED':
      return Colors.green;
    default:
      return Colors.blue;
  }
}
