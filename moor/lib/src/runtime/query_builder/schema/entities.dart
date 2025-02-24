part of '../query_builder.dart';

/// Some abstract schema entity that can be stored in a database. This includes
/// tables, triggers, views, indexes, etc.
abstract class DatabaseSchemaEntity {
  /// The (unalised) name of this entity in the database.
  String get entityColName;
}

/// A sqlite trigger that's executed before, after or instead of a subset of
/// writes on a specific tables.
/// In moor, triggers can only be declared in `.moor` files.
///
/// For more information on triggers, see the [CREATE TRIGGER][sqlite-docs]
/// documentation from sqlite, or the [entry on sqlitetutorial.net][sql-tut].
///
/// [sqlite-docs]: https://sqlite.org/lang_createtrigger.html
/// [sql-tut]: https://www.sqlitetutorial.net/sqlite-trigger/
class Trigger extends DatabaseSchemaEntity {
  /// The `CREATE TRIGGER` sql statement that can be used to create this
  /// trigger.
  final String createTriggerStmt;
  @override
  final String entityColName;

  /// Creates a trigger representation by the [createTriggerStmt] and its
  /// [entityColName]. Mainly used by generated code.
  Trigger(this.createTriggerStmt, this.entityColName);
}

/// A sqlite index on columns or expressions.
///
/// For more information on triggers, see the [CREATE TRIGGER][sqlite-docs]
/// documentation from sqlite, or the [entry on sqlitetutorial.net][sql-tut].
///
/// [sqlite-docs]: https://www.sqlite.org/lang_createindex.html
/// [sql-tut]: https://www.sqlitetutorial.net/sqlite-index/
class Index extends DatabaseSchemaEntity {
  @override
  final String entityColName;

  /// The `CREATE INDEX` sql statement that can be used to create this index.
  final String createIndexStmt;

  /// Creates an index model by the [createIndexStmt] and its [entityColName].
  /// Mainly used by generated code.
  Index(this.entityColName, this.createIndexStmt);
}

/// A sqlite view.
///
/// In moor, views can only be declared in `.moor` files.
///
/// For more information on views, see the [CREATE VIEW][sqlite-docs]
/// documentation from sqlite, or the [entry on sqlitetutorial.net][sql-tut].
///
/// [sqlite-docs]: https://www.sqlite.org/lang_createview.html
/// [sql-tut]: https://www.sqlitetutorial.net/sqlite-create-view/
abstract class View<Self, Row> extends ResultSetImplementation<Self, Row>
    implements HasResultSet {
  @override
  final String entityColName;

  /// The `CREATE VIEW` sql statement that can be used to create this view.
  final String createViewStmt;

  /// Creates an view model by the [createViewStmt] and its [entityColName].
  /// Mainly used by generated code.
  View(this.entityColName, this.createViewStmt);
}

/// An internal schema entity to run an sql statement when the database is
/// created.
///
/// The generator uses this entity to implement `@create` statements in moor
/// files:
/// ```sql
/// CREATE TABLE users (name TEXT);
///
/// @create: INSERT INTO users VALUES ('Bob');
/// ```
/// A [OnCreateQuery] is emitted for each `@create` statement in an included
/// moor file.
class OnCreateQuery extends DatabaseSchemaEntity {
  /// The sql statement that should be run in the default `onCreate` clause.
  final String sql;

  /// Create a query that will be run in the default `onCreate` migration.
  OnCreateQuery(this.sql);

  @override
  String get entityColName => r'$internal$';
}

/// Interface for schema entities that have a result set.
///
/// [Tbl] is the generated Dart class which implements [ResultSetImplementation]
/// and the user-defined [Table] class. [Row] is the class used to hold a result
/// row.
abstract class ResultSetImplementation<Tbl, Row> extends DatabaseSchemaEntity {
  /// The (potentially aliased) name of this table or view.
  ///
  /// If no alias is active, this is the same as [entityColName].
  String get aliasedName => entityColName;

  /// Type system sugar. Implementations are likely to inherit from both
  /// [TableInfo] and [Tbl] and can thus just return their instance.
  Tbl get asDslTable;

  /// All columns from this table or view.
  List<GeneratedColumn> get $columns;

  /// Maps the given row returned by the database into the fitting data class.
  Row map(Map<String, dynamic> data, {String? tablePrefix});

  /// Creates an alias of this table or view that will write the name [alias]
  /// when used in a query.
  ResultSetImplementation<Tbl, Row> createAlias(String alias) =>
      _AliasResultSet(alias, this);
}

class _AliasResultSet<Tbl, Row> extends ResultSetImplementation<Tbl, Row> {
  final String _alias;
  final ResultSetImplementation<Tbl, Row> _inner;

  _AliasResultSet(this._alias, this._inner);

  @override
  List<GeneratedColumn> get $columns => _inner.$columns;

  @override
  String get aliasedName => _alias;

  @override
  ResultSetImplementation<Tbl, Row> createAlias(String alias) {
    return _AliasResultSet(alias, _inner);
  }

  @override
  String get entityColName => _inner.entityColName;

  @override
  Row map(Map<String, dynamic> data, {String? tablePrefix}) {
    return _inner.map(data, tablePrefix: tablePrefix);
  }

  @override
  Tbl get asDslTable => _inner.asDslTable;
}

/// Extension to generate an alias for a table or a view.
extension NameWithAlias on ResultSetImplementation<dynamic, dynamic> {
  /// The table name, optionally suffixed with the alias if one exists. This
  /// can be used in select statements, as it returns something like "users u"
  /// for a table called users that has been aliased as "u".
  String get tableWithAlias {
    if (aliasedName == entityColName) {
      return entityColName;
    } else {
      return '$entityColName $aliasedName';
    }
  }
}
