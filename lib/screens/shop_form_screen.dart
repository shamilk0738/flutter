import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/shop.dart';
import '../services/repository.dart';
import '../widgets/state_views.dart';

class ShopFormScreen extends StatefulWidget {
  final Shop? shop;
  const ShopFormScreen({super.key, this.shop});

  @override
  State<ShopFormScreen> createState() => _ShopFormScreenState();
}

class _ShopFormScreenState extends State<ShopFormScreen> {
  final _form = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.shop?.name ?? '');
  late final _owner = TextEditingController(text: widget.shop?.ownerName ?? '');
  late final _phone = TextEditingController(text: widget.shop?.phone ?? '');
  late final _gst = TextEditingController(text: widget.shop?.gstNumber ?? '');
  late final _address = TextEditingController(text: widget.shop?.address ?? '');
  late final _pincode = TextEditingController(text: widget.shop?.pincode ?? '');
  late final _route = TextEditingController(
    text: widget.shop?.route?.toString() ?? '',
  );
  late final _salesman = TextEditingController(
    text: widget.shop?.salesman?.toString() ?? '',
  );

  late String? _district = keralaDistricts.contains(widget.shop?.district)
      ? widget.shop!.district
      : null;
  late bool _active = widget.shop?.isActive ?? true;
  bool _saving = false;

  bool get _editing => widget.shop != null;

  @override
  void dispose() {
    for (final c in [
      _name,
      _owner,
      _phone,
      _gst,
      _address,
      _pincode,
      _route,
      _salesman,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _intOrNull(String s) => s.trim().isEmpty ? null : int.tryParse(s.trim());

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'owner_name': _owner.text.trim(),
      'phone': _phone.text.trim(),
      'gst_number': _gst.text.trim().toUpperCase(),
      'address': _address.text.trim(),
      'district': _district,
      'pincode': _pincode.text.trim(),
      'route': _intOrNull(_route.text),
      'salesman': _intOrNull(_salesman.text),
      'is_active': _active,
    };

    try {
      if (_editing) {
        await Repository.instance.updateShop(widget.shop!.id, body);
      } else {
        await Repository.instance.createShop(body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), error: true);
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete shop?'),
        content: Text('"${widget.shop!.name}" Will be permanently deleted..'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await Repository.instance.deleteShop(widget.shop!.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), error: true);
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit shop' : 'Add shop'),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Shop name *'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter the shop name.'
                  : null,
            ),
            gap,
            TextFormField(
              controller: _owner,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Owner name'),
            ),
            gap,
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            gap,
            TextFormField(
              controller: _gst,
              textCapitalization: TextCapitalization.characters,
              maxLength: 15,
              decoration: const InputDecoration(
                labelText: 'GST number',
                hintText: '32ABCDE1234F1Z5',
              ),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isNotEmpty && s.length != 15) {
                  return 'GST number must be 15 characters long.';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            gap,
            DropdownButtonFormField<String>(
              value: _district,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'District *'),
              items: [
                for (final d in keralaDistricts)
                  DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: (v) => setState(() => _district = v),
              validator: (v) => v == null ? 'Please select a district.' : null,
            ),
            gap,
            TextFormField(
              controller: _pincode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Pincode'),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isNotEmpty && s.length != 6)
                  return 'Must be 6 digits long.';
                return null;
              },
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _route,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Route ID'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _salesman,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Salesman ID'),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(_editing ? 'Save changes' : 'Add shop'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
