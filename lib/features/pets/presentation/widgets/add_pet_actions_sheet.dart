import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

Future<void> showAddPetActionsSheet({
  required BuildContext context,
  required VoidCallback onCreatePet,
  required VoidCallback onJoinByCode,
}) {
  return showPawlyBottomSheet<void>(
    context: context,
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.pets_rounded),
            title: const Text('Создать питомца'),
            onTap: () {
              Navigator.of(context).pop();
              onCreatePet();
            },
          ),
          ListTile(
            leading: const Icon(Icons.key_rounded),
            title: const Text('По коду'),
            onTap: () {
              Navigator.of(context).pop();
              onJoinByCode();
            },
          ),
        ],
      );
    },
  );
}
