import 'package:flutter/material.dart';
import '../models/models.dart';

class ConnectionDialog extends StatefulWidget {
  final ConnectionProfile? existingProfile;

  const ConnectionDialog({super.key, this.existingProfile});

  @override
  State<ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends State<ConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _endpointController;
  late final TextEditingController _portController;
  late final TextEditingController _accessKeyController;
  late final TextEditingController _secretKeyController;
  late bool _useSSL;
  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    _nameController = TextEditingController(text: p?.name ?? '');
    _endpointController = TextEditingController(text: p?.endpoint ?? '');
    _portController = TextEditingController(text: '${p?.port ?? 443}');
    _accessKeyController = TextEditingController(text: p?.accessKey ?? '');
    _secretKeyController = TextEditingController(text: p?.secretKey ?? '');
    _useSSL = p?.useSSL ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _endpointController.dispose();
    _portController.dispose();
    _accessKeyController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProfile != null;

    return AlertDialog(
      title: Text(isEditing ? 'Verbindung bearbeiten' : 'Neue Verbindung'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'z.B. My MinIO Server',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name eingeben' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _endpointController,
                  decoration: const InputDecoration(
                    labelText: 'Server / Endpoint',
                    hintText: 'z.B. s3.myserver.com',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Endpoint eingeben' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _portController,
                        decoration: const InputDecoration(labelText: 'Port'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Port eingeben';
                          if (int.tryParse(v) == null) return 'Ungültig';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Switch(
                          value: _useSSL,
                          onChanged: (v) => setState(() => _useSSL = v),
                        ),
                        const Text('HTTPS'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accessKeyController,
                  decoration: const InputDecoration(labelText: 'Access Key'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Access Key eingeben' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _secretKeyController,
                  obscureText: _obscureSecret,
                  decoration: InputDecoration(
                    labelText: 'Secret Key',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureSecret
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscureSecret = !_obscureSecret),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Secret Key eingeben' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Speichern' : 'Hinzufügen'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final profile = ConnectionProfile(
      id:
          widget.existingProfile?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      endpoint: _endpointController.text.trim(),
      port: int.parse(_portController.text.trim()),
      useSSL: _useSSL,
      accessKey: _accessKeyController.text.trim(),
      secretKey: _secretKeyController.text.trim(),
    );

    Navigator.pop(context, profile);
  }
}
