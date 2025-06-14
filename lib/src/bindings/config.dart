import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:git2dart/src/extensions.dart';
import 'package:git2dart/src/helpers/error_helper.dart';
import 'package:git2dart_binaries/git2dart_binaries.dart';

/// Create a new config instance containing a single on-disk file. The returned
/// config must be freed with [free].
Pointer<git_config> open(String path) {
  return using((arena) {
    final out = arena<Pointer<git_config>>();
    final pathC = path.toChar(arena);
    final error = libgit2.git_config_open_ondisk(out, pathC);

    checkErrorAndThrow(error);

    return out.value;
  });
}

/// Open the global, XDG and system configuration files.
///
/// Utility wrapper that finds the global, XDG and system configuration
/// files and opens them into a single prioritized config object that can
/// be used when accessing default config data outside a repository.
///
/// The returned config must be freed with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_config> openDefault() {
  return using((arena) {
    final out = arena<Pointer<git_config>>();
    final error = libgit2.git_config_open_default(out);

    checkErrorAndThrow(error);

    return out.value;
  });
}

/// Open the global configuration for writing according to git's rules.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_config> openGlobal(Pointer<git_config> configPointer) {
  return using((arena) {
    final out = arena<Pointer<git_config>>();
    final error = libgit2.git_config_open_global(out, configPointer);

    checkErrorAndThrow(error);
    return out.value;
  });
}

/// Build a single-level focused config object from a multi-level one.
/// The returned config must be freed with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_config> openLevel({
  required Pointer<git_config> parentPointer,
  required int level,
}) {
  return using((arena) {
    final out = arena<Pointer<git_config>>();
    final error = libgit2.git_config_open_level(
      out,
      parentPointer,
      git_config_level_t.fromValue(level),
    );

    checkErrorAndThrow(error);
    return out.value;
  });
}

/// Add an on-disk config file to an existing config at the given [level].
///
/// Throws a [LibGit2Error] if error occured.
void addFileOndisk({
  required Pointer<git_config> configPointer,
  required String path,
  required int level,
  required Pointer<git_repository> repoPointer,
  bool force = false,
}) {
  using((arena) {
    final pathC = path.toChar(arena);
    final error = libgit2.git_config_add_file_ondisk(
      configPointer,
      pathC,
      git_config_level_t.fromValue(level),
      repoPointer,
      force ? 1 : 0,
    );

    checkErrorAndThrow(error);
  });
}

/// Set the write order for configuration backends.
///
/// Throws a [LibGit2Error] if error occured.
void setWriteOrder({
  required Pointer<git_config> configPointer,
  required List<int> levels,
}) {
  using((arena) {
    final levelsC = arena<Int>(levels.length);
    for (var i = 0; i < levels.length; i++) {
      levelsC[i] = levels[i];
    }
    final error = libgit2.git_config_set_writeorder(
      configPointer,
      levelsC,
      levels.length,
    );
    checkErrorAndThrow(error);
  });
}

/// Get a path value from the config.
///
/// Throws a [LibGit2Error] if error occured.
String getPath({
  required Pointer<git_config> configPointer,
  required String name,
}) {
  return using((arena) {
    final out = arena<git_buf>();
    final nameC = name.toChar(arena);
    final error = libgit2.git_config_get_path(out, configPointer, nameC);

    checkErrorAndThrow(error);

    final result = out.ref.ptr.toDartString(length: out.ref.size);
    libgit2.git_buf_dispose(out);
    return result;
  });
}

/// Locate the path to the global configuration file.
///
/// The user or global configuration file is usually located in
/// `$HOME/.gitconfig`.
///
/// This method will try to guess the full path to that file, if the file
/// exists. The returned path may be used to load the global configuration file.
///
/// This method will not guess the path to the xdg compatible config file
/// (`.config/git/config`).
///
/// Throws a [LibGit2Error] if error occured.
String findGlobal() {
  return using((arena) {
    final out = arena<git_buf>();
    final error = libgit2.git_config_find_global(out);

    checkErrorAndThrow(error);

    return out.ref.ptr.toDartString(length: out.ref.size);
  });
}

/// Locate the path to the system configuration file.
///
/// If `/etc/gitconfig` doesn't exist, it will look for
/// `%PROGRAMFILES%\Git\etc\gitconfig`
///
/// Throws a [LibGit2Error] if error occured.
String findSystem() {
  return using((arena) {
    final out = arena<git_buf>();
    final error = libgit2.git_config_find_system(out);

    checkErrorAndThrow(error);

    return out.ref.ptr.toDartString(length: out.ref.size);
  });
}

/// Locate the path to the global xdg compatible configuration file.
///
/// The xdg compatible configuration file is usually located in
/// `$HOME/.config/git/config`.
///
/// This method will try to guess the full path to that file, if the file
/// exists. The returned path may be used to load the xdg compatible
/// configuration file.
///
/// Throws a [LibGit2Error] if error occured.
String findXdg() {
  return using((arena) {
    final out = arena<git_buf>();
    final error = libgit2.git_config_find_xdg(out);

    checkErrorAndThrow(error);

    return out.ref.ptr.toDartString(length: out.ref.size);
  });
}

/// Create a snapshot of the configuration. The returned config must be freed
/// with [free].
///
/// Create a snapshot of the current state of a configuration, which allows you
/// to look into a consistent view of the configuration for looking up complex
/// values (e.g. a remote, submodule).
Pointer<git_config> snapshot(Pointer<git_config> config) {
  return using((arena) {
    final out = arena<Pointer<git_config>>();
    final error = libgit2.git_config_snapshot(out, config);

    checkErrorAndThrow(error);

    return out.value;
  });
}

/// Get the config entry of a config variable. The returned config entry must
/// be freed with [freeEntry].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_config_entry> getEntry({
  required Pointer<git_config> configPointer,
  required String variable,
}) {
  return using((arena) {
    final out = arena<Pointer<git_config_entry>>();
    final nameC = variable.toChar(arena);
    final error = libgit2.git_config_get_entry(out, configPointer, nameC);

    checkErrorAndThrow(error);

    return out.value;
  });
}

/// Set the value of a boolean config variable in the config file with the
/// highest level (usually the local one).
void setBool({
  required Pointer<git_config> configPointer,
  required String variable,
  required bool value,
}) {
  return using((arena) {
    final nameC = variable.toChar(arena);
    final valueC = value ? 1 : 0;
    final error = libgit2.git_config_set_bool(configPointer, nameC, valueC);

    checkErrorAndThrow(error);
  });
}

/// Set the value of an integer config variable in the config file with the
/// highest level (usually the local one).
void setInt({
  required Pointer<git_config> configPointer,
  required String variable,
  required int value,
}) {
  return using((arena) {
    final nameC = variable.toChar(arena);
    final error = libgit2.git_config_set_int64(configPointer, nameC, value);

    checkErrorAndThrow(error);
  });
}

/// Set the value of a string config variable in the config file with the
/// highest level (usually the local one).
void setString({
  required Pointer<git_config> configPointer,
  required String variable,
  required String value,
}) {
  return using((arena) {
    final nameC = variable.toChar(arena);
    final valueC = value.toChar(arena);
    final error = libgit2.git_config_set_string(configPointer, nameC, valueC);

    checkErrorAndThrow(error);
  });
}

/// Iterate over all the config variables. The returned iterator must be freed
/// with [freeIterator].
Pointer<git_config_iterator> iterator(Pointer<git_config> cfg) {
  return using((arena) {
    final out = arena<Pointer<git_config_iterator>>();
    final error = libgit2.git_config_iterator_new(out, cfg);

    checkErrorAndThrow(error);

    return out.value;
  });
}

/// Delete a config variable from the config file with the highest level
/// (usually the local one).
///
/// Throws a [LibGit2Error] if error occured.
void delete({
  required Pointer<git_config> configPointer,
  required String variable,
}) {
  return using((arena) {
    final nameC = variable.toChar(arena);
    final error = libgit2.git_config_delete_entry(configPointer, nameC);

    checkErrorAndThrow(error);
  });
}

/// Iterate over the values of a multivar.
///
/// If [regexp] is present, then the iterator will only iterate over all
/// values which match the pattern.
///
/// The regular expression is applied case-sensitively on the normalized form
/// of the variable name: the section and variable parts are lower-cased. The
/// subsection is left unchanged.
List<String> multivarValues({
  required Pointer<git_config> configPointer,
  required String variable,
  String? regexp,
}) {
  return using((arena) {
    final nameC = variable.toChar(arena);
    final regexpC = regexp?.toChar(arena) ?? nullptr;
    final iterator = arena<Pointer<git_config_iterator>>();
    final entry = arena<Pointer<git_config_entry>>();

    final error = libgit2.git_config_multivar_iterator_new(
      iterator,
      configPointer,
      nameC,
      regexpC,
    );

    checkErrorAndThrow(error);

    var nextError = 0;
    final entries = <String>[];

    while (nextError == 0) {
      nextError = libgit2.git_config_next(entry, iterator.value);
      if (nextError != -31) {
        entries.add(entry.value.ref.value.toDartString());
      } else {
        break;
      }
    }

    return entries;
  });
}

/// Free the configuration and its associated memory and files.
void free(Pointer<git_config> cfg) => libgit2.git_config_free(cfg);

/// Free a config entry.
void freeEntry(Pointer<git_config_entry> entry) =>
    libgit2.git_config_entry_free(entry);

/// Free a config iterator.
void freeIterator(Pointer<git_config_iterator> iter) =>
    libgit2.git_config_iterator_free(iter);

/// Get a string value from a config.
///
/// The returned string must be freed with [free].
///
/// Throws a [LibGit2Error] if error occurred.
String getStringBuf({
  required Pointer<git_config> configPointer,
  required String name,
}) {
  return using((arena) {
    final out = arena<git_buf>();
    final nameC = name.toChar(arena);
    final error = libgit2.git_config_get_string_buf(out, configPointer, nameC);

    checkErrorAndThrow(error);

    libgit2.git_buf_dispose(out);

    return out.ref.ptr.toDartString(length: out.ref.size);
  });
}

/// Set a multivar in the local config file.
///
/// The [regexp] is a regular expression to indicate which values to replace.
///
/// Throws a [LibGit2Error] if error occurred.
void setMultivar({
  required Pointer<git_config> configPointer,
  required String name,
  required String regexp,
  required String value,
}) {
  return using((arena) {
    final nameC = name.toChar(arena);
    final regexpC = regexp.toChar(arena);
    final valueC = value.toChar(arena);
    final error = libgit2.git_config_set_multivar(
      configPointer,
      nameC,
      regexpC,
      valueC,
    );

    checkErrorAndThrow(error);
  });
}

/// Delete a multivar from the local config file.
///
/// The [regexp] is a regular expression to indicate which values to delete.
///
/// Throws a [LibGit2Error] if error occurred.
void deleteMultivar({
  required Pointer<git_config> configPointer,
  required String name,
  required String regexp,
}) {
  return using((arena) {
    final nameC = name.toChar(arena);
    final regexpC = regexp.toChar(arena);
    final error = libgit2.git_config_delete_multivar(
      configPointer,
      nameC,
      regexpC,
    );

    checkErrorAndThrow(error);
  });
}
