import 'package:chess/chess.dart' as ch;

/// The rules of chess for the board on the phone (the `chess` package). The server checks every move again —
/// this only makes a move show at once and tells the board where a piece may go.

/// A legal move in the current position.
class LegalMove {
  const LegalMove(this._move);

  final ch.Move _move;

  String get from => _move.fromAlgebraic;
  String get to => _move.toAlgebraic;

  /// "q", "r", "b", "n" when a pawn reaches the last rank.
  String? get promotion => _move.promotion?.name;
  bool get isCapture => _move.captured != null;

  /// As the server takes it: "e2e4", "e7e8q".
  String get uci => '$from$to${promotion ?? ''}';
}

/// A game rebuilt from its moves.
class Position {
  Position._(this._chess, this.san);

  /// The game with these moves ("e2e4") played from the starting position. Moves that aren't legal end the
  /// replay there (the server never sends one).
  factory Position.replay(List<String> moves) {
    final chess = ch.Chess();
    final san = <String>[];
    for (final uci in moves) {
      final move = chess.generate_moves().where((m) => LegalMove(m).uci == uci).firstOrNull;
      if (move == null) break;
      san.add(chess.move_to_san(move));
      chess.make_move(move);
    }
    return Position._(chess, san);
  }

  final ch.Chess _chess;

  /// The moves in notation ("e4", "Nf3", "O-O"), for the move list.
  final List<String> san;

  /// "w" or "b".
  String get turn => _chess.turn == ch.Color.WHITE ? 'w' : 'b';
  bool get inCheck => _chess.in_check;

  late final List<LegalMove> legalMoves = _chess.generate_moves().map(LegalMove.new).toList();

  /// "wK", "bP" … on this square ("e4"), or null.
  String? pieceAt(String square) {
    final piece = _chess.get(square);
    if (piece == null) return null;
    return '${piece.color == ch.Color.WHITE ? 'w' : 'b'}${piece.type.name.toUpperCase()}';
  }

  /// The square of the king of the side to move.
  String? get kingSquare {
    for (final square in allSquares) {
      if (pieceAt(square) == '${turn}K') return square;
    }
    return null;
  }
}

const _files = 'abcdefgh';

/// a8 … h8, then down to a1 … h1 — the order a board is drawn in from White's side.
final List<String> allSquares = [
  for (var rank = 8; rank >= 1; rank--)
    for (var file = 0; file < 8; file++) '${_files[file]}$rank',
];

/// a1 is dark.
bool isDarkSquare(String square) => (_files.indexOf(square[0]) + int.parse(square[1])) % 2 == 1;
