import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:git2dart/src/bindings/oid.dart' as oid_bindings;
import 'package:git2dart/src/extensions.dart';
import 'package:git2dart/src/helpers/error_helper.dart';
import 'package:git2dart/src/oid.dart';
import 'package:git2dart_binaries/git2dart_binaries.dart';

/// Create a new object database with no backends. The returned odb must be
/// freed with [free].
///
/// Before the ODB can be used for read/writing, a custom database backend must be
/// manually added.
Pointer<git_odb> create({git_oid_t oidType = git_oid_t.GIT_OID_SHA1}) {
  return using((arena) {
    final out = arena<Pointer<git_odb>>();
    final opts = arena<git_odb_options>();
    opts.ref.version = GIT_ODB_OPTIONS_VERSION;
    opts.ref.oid_typeAsInt = oidType.value;

    final error = libgit2.git_odb_new(out, opts);
    checkErrorAndThrow(error);
    return out.value;
  });
}

/// Open an existing object database from the given `objects` directory.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_odb> open({
  required String objectsDir,
  git_oid_t oidType = git_oid_t.GIT_OID_SHA1,
}) {
  return using((arena) {
    final out = arena<Pointer<git_odb>>();
    final pathC = objectsDir.toChar(arena);
    final opts = arena<git_odb_options>();
    opts.ref.version = GIT_ODB_OPTIONS_VERSION;
    opts.ref.oid_typeAsInt = oidType.value;

    final error = libgit2.git_odb_open(out, pathC, opts);
    checkErrorAndThrow(error);
    return out.value;
  });
}

/// Add an on-disk alternate to an existing Object DB.
///
/// Note that the added path must point to an `objects`, not to a full
/// repository, to use it as an alternate store.
///
/// Alternate backends are always checked for objects after all the main
/// backends have been exhausted.
///
/// Writing is disabled on alternate backends.
void addDiskAlternate({
  required Pointer<git_odb> odbPointer,
  required String path,
}) {
  return using((arena) {
    final pathC = path.toChar(arena);
    libgit2.git_odb_add_disk_alternate(odbPointer, pathC);
  });
}

/// Determine if an object can be found in the object database by an
/// abbreviated object ID.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> existsPrefix({
  required Pointer<git_odb> odbPointer,
  required Pointer<git_oid> shortOidPointer,
  required int length,
}) {
  final out = calloc<git_oid>();
  final error = libgit2.git_odb_exists_prefix(
    out,
    odbPointer,
    shortOidPointer,
    length,
  );
  checkErrorAndThrow(error);
  return out;
}

/// Determine if the given object can be found in the object database.
bool exists({
  required Pointer<git_odb> odbPointer,
  required Pointer<git_oid> oidPointer,
}) {
  return libgit2.git_odb_exists(odbPointer, oidPointer) == 1 || false;
}

/// Determine if the given object can be found in the object database using
/// extended lookup flags.
bool existsExt({
  required Pointer<git_odb> odbPointer,
  required Pointer<git_oid> oidPointer,
  required int flags,
}) {
  return libgit2.git_odb_exists_ext(odbPointer, oidPointer, flags) == 1 ||
      false;
}

/// List of objects in the database.
///
/// IMPORTANT: make sure to clear that list since it's a global variable.
var _objects = <Oid>[];

/// The callback to call for each object.
int _forEachCb(Pointer<git_oid> oid, Pointer<Void> payload) {
  _objects.add(Oid(oid_bindings.copy(oid)));
  return 0;
}

/// List all objects available in the database.
///
/// Throws a [LibGit2Error] if error occured.
List<Oid> objects(Pointer<git_odb> odb) {
  const except = -1;
  final cb =
      Pointer.fromFunction<Int Function(Pointer<git_oid>, Pointer<Void>)>(
        _forEachCb,
        except,
      );
  final error = libgit2.git_odb_foreach(odb, cb, nullptr);
  checkErrorAndThrow(error);

  final result = _objects.toList(growable: false);
  _objects.clear();

  return result;
}

/// Determine if multiple objects exist in the database based on abbreviated
/// identifiers.
void expandIds({
  required Pointer<git_odb> odbPointer,
  required Pointer<git_odb_expand_id> idsPointer,
  required int count,
}) {
  final error = libgit2.git_odb_expand_ids(odbPointer, idsPointer, count);
  checkErrorAndThrow(error);
}

/// Refresh the object database to load newly added files.
void refresh(Pointer<git_odb> odbPointer) {
  final error = libgit2.git_odb_refresh(odbPointer);
  checkErrorAndThrow(error);
}

/// Read an object from the database. The returned object must be freed with
/// [freeObject].
///
/// This method queries all available ODB backends trying to read the given OID.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_odb_object> read({
  required Pointer<git_odb> odbPointer,
  required Pointer<git_oid> oidPointer,
}) {
  return using((arena) {
    final out = arena<Pointer<git_odb_object>>();
    final error = libgit2.git_odb_read(out, odbPointer, oidPointer);

    checkErrorAndThrow(error);

    return out.value;
  });
}

/// Read an object from the database given a prefix of its identifier.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_odb_object> readPrefix({
  required Pointer<git_odb> odbPointer,
  required Pointer<git_oid> shortOidPointer,
  required int length,
}) {
  return using((arena) {
    final out = arena<Pointer<git_odb_object>>();
    final error = libgit2.git_odb_read_prefix(
      out,
      odbPointer,
      shortOidPointer,
      length,
    );
    checkErrorAndThrow(error);
    return out.value;
  });
}

/// Return the OID of an ODB object.
///
/// This is the OID from which the object was read from.
Pointer<git_oid> objectId(Pointer<git_odb_object> object) {
  return libgit2.git_odb_object_id(object);
}

/// Return the type of an ODB object.
git_object_t objectType(Pointer<git_odb_object> object) {
  return libgit2.git_odb_object_type(object);
}

/// Return the data of an ODB object.
///
/// This is the uncompressed, raw data as read from the ODB, without the
/// leading header.
String objectData(Pointer<git_odb_object> object) {
  return libgit2.git_odb_object_data(object).cast<Utf8>().toDartString();
}

/// Return the data of an ODB object as bytes.
Uint8List objectDataBytes(Pointer<git_odb_object> object) {
  final size = libgit2.git_odb_object_size(object);
  if (size == 0) return Uint8List(0);
  final data = libgit2
      .git_odb_object_data(object)
      .cast<Uint8>()
      .asTypedList(size);
  return Uint8List.fromList(data);
}

/// Return the size of an ODB object.
///
/// This is the real size of the `data` buffer, not the actual size of the
/// object.
int objectSize(Pointer<git_odb_object> object) {
  return libgit2.git_odb_object_size(object);
}

/// Read the header of an object from the database without reading its data.
///
/// Returns a map containing `size` and `type` keys.
/// Throws a [LibGit2Error] if error occured.
Map<String, Object> readHeader({
  required Pointer<git_odb> odbPointer,
  required Pointer<git_oid> oidPointer,
}) {
  return using((arena) {
    final lenOut = arena<Size>();
    final typeOut = arena<Int>();
    final error = libgit2.git_odb_read_header(
      lenOut,
      typeOut,
      odbPointer,
      oidPointer,
    );
    checkErrorAndThrow(error);
    return {
      'size': lenOut.value,
      'type': git_object_t.fromValue(typeOut.value),
    };
  });
}

/// Write raw data into the object database.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> write({
  required Pointer<git_odb> odbPointer,
  required git_object_t type,
  required String data,
}) {
  return using((arena) {
    final stream = arena<Pointer<git_odb_stream>>();
    final streamError = libgit2.git_odb_open_wstream(
      stream,
      odbPointer,
      data.length,
      type,
    );
    checkErrorAndThrow(streamError);

    final bufferC = data.toChar(arena);
    libgit2.git_odb_stream_write(stream.value, bufferC, data.length);

    final out = calloc<git_oid>();
    final error = libgit2.git_odb_stream_finalize_write(out, stream.value);
    checkErrorAndThrow(error);

    libgit2.git_odb_stream_free(stream.value);
    return out;
  });
}

/// Close an open object database.
void free(Pointer<git_odb> db) => libgit2.git_odb_free(db);

/// Close an ODB object.
///
/// This method must always be called once a odb object is no longer needed,
/// otherwise memory will leak.
void freeObject(Pointer<git_odb_object> object) {
  libgit2.git_odb_object_free(object);
}
