import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:git2dart/src/extensions.dart';
import 'package:git2dart/src/helpers/error_helper.dart';
import 'package:git2dart_binaries/git2dart_binaries.dart';

/// Initializes a rebase operation to rebase the changes in [branchPointer]
/// relative to [upstreamPointer] onto [ontoPointer] another branch. To begin
/// the rebase process, call [next]. The returned rebase must be freed with
/// [free].
///
/// [branchPointer] is the terminal commit to rebase, or null to rebase the
/// current branch.
///
/// [upstreamPointer] is the commit to begin rebasing from, or null to rebase
/// all reachable commits.
///
/// [ontoPointer] is the branch to rebase onto, or null to rebase onto the
/// given upstream.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_rebase> init({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_annotated_commit>? branchPointer,
  required Pointer<git_annotated_commit>? upstreamPointer,
  required Pointer<git_annotated_commit>? ontoPointer,
}) {
  return using((arena) {
    final out = arena<Pointer<git_rebase>>();
    final opts = arena<git_rebase_options>();

    final error = libgit2.git_rebase_options_init(
      opts,
      GIT_REBASE_OPTIONS_VERSION,
    );
    checkErrorAndThrow(error);

    final initError = libgit2.git_rebase_init(
      out,
      repoPointer,
      branchPointer ?? nullptr,
      upstreamPointer ?? nullptr,
      ontoPointer ?? nullptr,
      opts,
    );
    checkErrorAndThrow(initError);

    return out.value;
  });
}

/// Opens an existing rebase that was previously started by either an
/// invocation of [init] or by another client. The returned rebase must be
/// freed with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_rebase> open(Pointer<git_repository> repo) {
  return using((arena) {
    final out = arena<Pointer<git_rebase>>();
    final opts = arena<git_rebase_options>();

    final error = libgit2.git_rebase_options_init(
      opts,
      GIT_REBASE_OPTIONS_VERSION,
    );
    checkErrorAndThrow(error);

    final openError = libgit2.git_rebase_open(out, repo, opts);
    checkErrorAndThrow(openError);

    return out.value;
  });
}

/// Gets the count of rebase operations that are to be applied.
int operationsCount(Pointer<git_rebase> rebase) =>
    libgit2.git_rebase_operation_entrycount(rebase);

/// Gets the rebase operation specified by the given index.
Pointer<git_rebase_operation> getOperationByIndex({
  required Pointer<git_rebase> rebase,
  required int index,
}) {
  return libgit2.git_rebase_operation_byindex(rebase, index);
}

/// Gets the index of the rebase operation that is currently being applied. If
/// the first operation has not yet been applied (because you have called [init]
/// but not yet [next]) then this returns `-1`.
int currentOperation(Pointer<git_rebase> rebase) =>
    libgit2.git_rebase_operation_current(rebase);

/// Performs the next rebase operation and returns the information about it.
/// If the operation is one that applies a patch (which is any operation except
/// GIT_REBASE_OPERATION_EXEC) then the patch will be applied and the index and
/// working directory will be updated with the changes. If there are conflicts,
/// you will need to address those before committing the changes.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_rebase_operation> next(Pointer<git_rebase> rebase) {
  return using((arena) {
    final out = arena<Pointer<git_rebase_operation>>();
    final error = libgit2.git_rebase_next(out, rebase);

    checkErrorAndThrow(error);

    return out.value;
  });
}

/// Commits the current patch. You must have resolved any conflicts that were
/// introduced during the patch application from the [next] invocation.
///
/// Throws a [LibGit2Error] if error occured.
void commit({
  required Pointer<git_rebase> rebasePointer,
  required Pointer<git_signature>? authorPointer,
  required Pointer<git_signature> committerPointer,
  required String? message,
}) {
  return using((arena) {
    final out = arena<git_oid>();
    final messageC = message?.toChar(arena) ?? nullptr;

    final error = libgit2.git_rebase_commit(
      out,
      rebasePointer,
      authorPointer ?? nullptr,
      committerPointer,
      nullptr,
      messageC,
    );
    checkErrorAndThrow(error);
  });
}

/// Get the index produced by the last operation when rebasing in-memory.
Pointer<git_index> inmemoryIndex(Pointer<git_rebase> rebase) {
  return using((arena) {
    final out = arena<Pointer<git_index>>();
    final error = libgit2.git_rebase_inmemory_index(out, rebase);
    checkErrorAndThrow(error);
    return out.value;
  });
}

/// Finishes a rebase that is currently in progress once all patches have been
/// applied.
void finish(Pointer<git_rebase> rebase) =>
    libgit2.git_rebase_finish(rebase, nullptr);

/// Aborts a rebase that is currently in progress, resetting the repository and
/// working directory to their state before rebase began.
void abort(Pointer<git_rebase> rebase) => libgit2.git_rebase_abort(rebase);

/// Gets the original HEAD id for merge rebases.
Pointer<git_oid> origHeadOid(Pointer<git_rebase> rebase) =>
    libgit2.git_rebase_orig_head_id(rebase);

/// Gets the original HEAD ref name for merge rebases.
String origHeadName(Pointer<git_rebase> rebase) {
  final result = libgit2.git_rebase_orig_head_name(rebase);
  return result == nullptr ? '' : result.toDartString();
}

/// Gets the onto id for merge rebases.
Pointer<git_oid> ontoOid(Pointer<git_rebase> rebase) =>
    libgit2.git_rebase_onto_id(rebase);

/// Gets the onto ref name for merge rebases.
String ontoName(Pointer<git_rebase> rebase) =>
    libgit2.git_rebase_onto_name(rebase).toDartString();

/// Free memory allocated for rebase object.
void free(Pointer<git_rebase> rebase) => libgit2.git_rebase_free(rebase);
