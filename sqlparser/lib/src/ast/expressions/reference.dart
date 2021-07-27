part of '../ast.dart';

/// Expression that refers to an individual expression declared somewhere else
/// in the table.
///
/// For instance, in "SELECT table.c FROM table", the "table.c" is a reference
/// that refers to the column "c" in a table "table". In "SELECT COUNT(*) AS c,
/// 2 * c AS d FROM table", the "c" after the "2 *" is a reference that refers
/// to the expression "COUNT(*)".
class Reference extends Expression with ReferenceOwner {
  /// An optional schema name.
  ///
  /// When this is non-null, [entityColName] will not be null either.
  final String? schemaName;

  /// Entity can be either a table or a view.
  final String? entityColName;
  final String columnName;

  /// The resolved result set from the [entityColName].
  ResultSetAvailableInStatement? resultEntity;

  Column? get resolvedColumn => resolved as Column?;

  Reference({this.entityColName, this.schemaName, required this.columnName})
      : assert(
          entityColName != null || schemaName == null,
          'When setting a schemaName, entityColName must not be null either.',
        );

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitReference(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  String toString() {
    final result = StringBuffer();

    if (schemaName != null) {
      result..write(schemaName)..write('.');
    }
    if (entityColName != null) {
      result..write(entityColName)..write('.');
    }
    result.write(columnName);

    return result.toString();
  }
}
