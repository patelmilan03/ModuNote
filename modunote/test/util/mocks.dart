import 'package:mocktail/mocktail.dart';
import 'package:modunote/data/repositories/interfaces/i_note_repository.dart';
import 'package:modunote/data/repositories/interfaces/i_tag_repository.dart';
import 'package:modunote/services/remote/remote_note_service.dart';

/// Shared mocktail doubles for the repository/service collaborators that
/// view-models depend on. View-models import the *interfaces*, so mocking the
/// interface (or the plain service class) is enough to drive them.
class MockNoteRepository extends Mock implements INoteRepository {}

class MockTagRepository extends Mock implements ITagRepository {}

class MockRemoteNoteService extends Mock implements RemoteNoteService {}
