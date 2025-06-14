import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:git2dart/src/extensions.dart';
import 'package:git2dart/src/helpers/error_helper.dart';
import 'package:git2dart_binaries/git2dart_binaries.dart';

typedef CheckoutProgress = void Function(String path, int completed, int total);
typedef CheckoutPerfdata =
    void Function(Pointer<git_checkout_perfdata> perfdata);

CheckoutProgress? _progress;
CheckoutPerfdata? _perfdata;

void _progressCb(
  Pointer<Char> path,
  int completed,
  int total,
  Pointer<Void> payload,
) {
  _progress?.call(path == nullptr ? '' : path.toDartString(), completed, total);
}

void _perfdataCb(
  Pointer<git_checkout_perfdata> perfdata,
  Pointer<Void> payload,
) {
  _perfdata?.call(perfdata);
}

/// Updates files in the index and the working tree to match the content of the
/// commit pointed at by HEAD.
///
/// Note that this is not the correct mechanism used to switch branches; do not
/// change your HEAD and then call this method, that would leave you with
/// checkout conflicts since your working directory would then appear to be
/// dirty. Instead, checkout the target of the branch and then update HEAD
/// using [setHead] to point to the branch you checked out.
///
/// Throws a [LibGit2Error] if error occurred.
void head({
  required Pointer<git_repository> repoPointer,
  required int strategy,
  String? directory,
  List<String>? paths,
}) {
  using((arena) {
    final optsC = arena<git_checkout_options>();
    libgit2.git_checkout_options_init(optsC, GIT_CHECKOUT_OPTIONS_VERSION);

    optsC.ref.checkout_strategy = strategy;

    if (directory != null) {
      optsC.ref.target_directory = directory.toChar(arena);
    }

    if (paths != null) {
      final pathPointers = paths.map((e) => e.toChar(arena)).toList();
      final strArray = arena<Pointer<Char>>(paths.length);
      for (var i = 0; i < paths.length; i++) {
        strArray[i] = pathPointers[i];
      }
      optsC.ref.paths.strings = strArray;
      optsC.ref.paths.count = paths.length;
    }

    final error = libgit2.git_checkout_head(repoPointer, optsC);
    checkErrorAndThrow(error);
  });
}

/// Checkout HEAD with optional progress and performance callbacks.
void headWithCallbacks({
  required Pointer<git_repository> repoPointer,
  required int strategy,
  CheckoutProgress? progress,
  CheckoutPerfdata? perfdata,
}) {
  using((arena) {
    final optsC = arena<git_checkout_options>();
    libgit2.git_checkout_options_init(optsC, GIT_CHECKOUT_OPTIONS_VERSION);
    optsC.ref.checkout_strategy = strategy;

    if (progress != null) {
      _progress = progress;
      optsC.ref.progress_cb =
          Pointer.fromFunction<git_checkout_progress_cbFunction>(_progressCb);
    }
    if (perfdata != null) {
      _perfdata = perfdata;
      optsC.ref.perfdata_cb =
          Pointer.fromFunction<git_checkout_perfdata_cbFunction>(_perfdataCb);
    }

    final error = libgit2.git_checkout_head(repoPointer, optsC);
    _progress = null;
    _perfdata = null;
    checkErrorAndThrow(error);
  });
}

/// Updates files in the working tree to match the content of the index.
///
/// Throws a [LibGit2Error] if error occurred.
void index({
  required Pointer<git_repository> repoPointer,
  required int strategy,
  String? directory,
  List<String>? paths,
}) {
  using((arena) {
    final optsC = arena<git_checkout_options>();
    libgit2.git_checkout_options_init(optsC, GIT_CHECKOUT_OPTIONS_VERSION);

    optsC.ref.checkout_strategy = strategy;

    if (directory != null) {
      optsC.ref.target_directory = directory.toChar(arena);
    }

    if (paths != null) {
      final pathPointers = paths.map((e) => e.toChar(arena)).toList();
      final strArray = arena<Pointer<Char>>(paths.length);
      for (var i = 0; i < paths.length; i++) {
        strArray[i] = pathPointers[i];
      }
      optsC.ref.paths.strings = strArray;
      optsC.ref.paths.count = paths.length;
    }

    final error = libgit2.git_checkout_index(repoPointer, nullptr, optsC);
    checkErrorAndThrow(error);
  });
}

/// Updates files in the index and working tree to match the content of the tree
/// pointed at by the treeish.
///
/// Throws a [LibGit2Error] if error occurred.
void tree({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_object> treeishPointer,
  required int strategy,
  String? directory,
  List<String>? paths,
}) {
  using((arena) {
    final optsC = arena<git_checkout_options>();
    libgit2.git_checkout_options_init(optsC, GIT_CHECKOUT_OPTIONS_VERSION);

    optsC.ref.checkout_strategy = strategy;

    if (directory != null) {
      optsC.ref.target_directory = directory.toChar(arena);
    }

    if (paths != null) {
      final pathPointers = paths.map((e) => e.toChar(arena)).toList();
      final strArray = arena<Pointer<Char>>(paths.length);
      for (var i = 0; i < paths.length; i++) {
        strArray[i] = pathPointers[i];
      }
      optsC.ref.paths.strings = strArray;
      optsC.ref.paths.count = paths.length;
    }

    final error = libgit2.git_checkout_tree(repoPointer, treeishPointer, optsC);
    checkErrorAndThrow(error);
  });
}

/// Initialize checkout options with the given parameters.
///
/// Returns a list containing:
/// - [0]: Pointer to checkout options
/// - [1]: List of path pointers that need to be freed
/// - [2]: String array pointer that needs to be freed
List<Object> initOptions({
  required int strategy,
  required Arena arena,
  String? directory,
  List<String>? paths,
}) {
  final optsC = calloc<git_checkout_options>();
  libgit2.git_checkout_options_init(optsC, GIT_CHECKOUT_OPTIONS_VERSION);

  optsC.ref.checkout_strategy = strategy;

  if (directory != null) {
    optsC.ref.target_directory = directory.toChar(arena);
  }

  var pathPointers = <Pointer<Char>>[];
  Pointer<Pointer<Char>> strArray = nullptr;
  if (paths != null) {
    pathPointers = paths.map((e) => e.toChar(arena)).toList();
    strArray = calloc(paths.length);
    for (var i = 0; i < paths.length; i++) {
      strArray[i] = pathPointers[i];
    }
    optsC.ref.paths.strings = strArray;
    optsC.ref.paths.count = paths.length;
  }

  return [optsC, pathPointers, strArray];
}
