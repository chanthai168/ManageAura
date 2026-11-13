class Supplier {
  final String id;
  String name;
  String phone;
  String email;

  Supplier({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
  }) {
    if (id.trim().isEmpty) throw ArgumentError('Supplier id cannot be empty');
    if (name.trim().isEmpty) throw ArgumentError('Supplier name cannot be empty');
  }

  @override
  String toString() => 'Supplier($id, $name)';
}
