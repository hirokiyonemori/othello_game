import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ランキングエントリクラス
class RankingEntry {
  final String playerName;
  final int score;
  final int difficulty;
  final bool isNPC;
  final DateTime date;
  final bool playerWon;

  RankingEntry({
    required this.playerName,
    required this.score,
    required this.difficulty,
    required this.isNPC,
    required this.date,
    required this.playerWon,
  });

  Map<String, dynamic> toJson() {
    return {
      'playerName': playerName,
      'score': score,
      'difficulty': difficulty,
      'isNPC': isNPC,
      'date': date.toIso8601String(),
      'playerWon': playerWon,
    };
  }

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      playerName: json['playerName'],
      score: json['score'],
      difficulty: json['difficulty'],
      isNPC: json['isNPC'],
      date: DateTime.parse(json['date']),
      playerWon: json['playerWon'],
    );
  }
}

// ランキング管理クラス
class RankingManager {
  static const String _rankingKey = 'game_ranking';
  static const int _maxEntries = 50; // 最大保存件数

  // ローカルランキングを保存
  static Future<void> saveLocalRanking(RankingEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> rankingList = prefs.getStringList(_rankingKey) ?? [];
      // 新しいエントリを追加
      rankingList.add(jsonEncode(entry.toJson()));
      // スコアでソート（降順）
      rankingList.sort((a, b) {
        final entryA = RankingEntry.fromJson(jsonDecode(a));
        final entryB = RankingEntry.fromJson(jsonDecode(b));
        return entryB.score.compareTo(entryA.score);
      });
      // 最大件数を超えたら古いものを削除
      if (rankingList.length > _maxEntries) {
        rankingList = rankingList.take(_maxEntries).toList();
      }
      await prefs.setStringList(_rankingKey, rankingList);
    } catch (e) {
      print('Error saving local ranking: $e');
    }
  }

  // ローカルランキングを読み込み
  static Future<List<RankingEntry>> loadLocalRanking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> rankingList = prefs.getStringList(_rankingKey) ?? [];
      return rankingList
          .map((json) => RankingEntry.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Error loading local ranking: $e');
      return [];
    }
  }

  // ローカルランキングをクリア
  static Future<void> clearLocalRanking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rankingKey);
    } catch (e) {
      print('Error clearing local ranking: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const OthelloApp());
}

class OthelloApp extends StatelessWidget {
  const OthelloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'オセロゲーム',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const GameModeSelection(),
    );
  }
}

class GameModeSelection extends StatefulWidget {
  const GameModeSelection({super.key});

  @override
  State<GameModeSelection> createState() => _GameModeSelectionState();
}

class _GameModeSelectionState extends State<GameModeSelection> {
  void _navigateToGame(bool isNPC) {
    if (isNPC) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DifficultySelection(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OthelloGame(isNPC: false),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('オセロゲーム'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'プレイモードを選択してください',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            _buildModeButton(
              context,
              '二人プレイ',
              '友達と一緒にプレイ',
              Icons.people,
              Colors.blue,
              () => _navigateToGame(false),
            ),
            const SizedBox(height: 20),
                              _buildModeButton(
                    context,
                    'NPCプレイ',
                    'AIと対戦（難易度選択）',
                    Icons.computer,
                    Colors.orange,
                    () => _navigateToGame(true),
                  ),
                  const SizedBox(height: 20),
                  _buildModeButton(
                    context,
                    'ランキング',
                    'スコアランキングを見る',
                    Icons.leaderboard,
                    Colors.purple,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RankingScreen(),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: 300,
      height: 110,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DifficultySelection extends StatefulWidget {
  const DifficultySelection({super.key});

  @override
  State<DifficultySelection> createState() => _DifficultySelectionState();
}

class _DifficultySelectionState extends State<DifficultySelection> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('難易度選択'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '難易度を選択してください',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            _buildDifficultyButton('初級', 1, Colors.green),
            const SizedBox(height: 20),
            _buildDifficultyButton('中級', 2, Colors.orange),
            const SizedBox(height: 20),
            _buildDifficultyButton('上級', 3, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String title, int difficulty, Color color) {
    return Container(
      width: 200,
      height: 80,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OthelloGame(
                isNPC: true,
                difficulty: difficulty,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<RankingEntry> _localRankings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalRankings();
  }

  Future<void> _loadLocalRankings() async {
    setState(() {
      _isLoading = true;
    });
    final rankings = await RankingManager.loadLocalRanking();
    setState(() {
      _localRankings = rankings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLocalRankings,
            tooltip: '更新',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showClearDialog,
            tooltip: 'ローカルランキングをクリア',
          ),
        ],
      ),
      body: _buildLocalRankingTab(),
    );
  }

  Widget _buildLocalRankingTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_localRankings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'ローカルランキングデータがありません',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'ゲームをプレイしてスコアを記録しましょう！',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _localRankings.length,
      itemBuilder: (context, index) {
        final entry = _localRankings[index];
        return _buildRankingCard(entry, index + 1);
      },
    );
  }

  Widget _buildRankingCard(RankingEntry entry, int rank) {
    final isTop3 = rank <= 3;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isTop3 ? _getRankColor(rank) : Colors.grey,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          entry.playerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('スコア: ${entry.score}'),
            Text(
              entry.isNPC 
                ? 'AI対戦 (レベル${entry.difficulty})'
                : '二人プレイ',
            ),
            Text(
              '${entry.date.year}/${entry.date.month.toString().padLeft(2, '0')}/${entry.date.day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: entry.playerWon ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            entry.playerWon ? '勝利' : '敗北',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return Colors.amber; // 金
      case 2: return Colors.grey; // 銀
      case 3: return Colors.brown; // 銅
      default: return Colors.grey;
    }
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ローカルランキングをクリア'),
        content: const Text('すべてのローカルランキングデータを削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await RankingManager.clearLocalRanking();
              _loadLocalRankings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class OthelloGame extends StatefulWidget {
  final bool isNPC;
  final int difficulty;

  const OthelloGame({
    super.key,
    required this.isNPC,
    this.difficulty = 1,
  });

  @override
  State<OthelloGame> createState() => _OthelloGameState();
}

class _OthelloGameState extends State<OthelloGame> {
  static const int boardSize = 8;
  late List<List<int>> board;
  int currentPlayer = 1; // 1: 黒, 2: 白
  bool gameOver = false;
  int blackScore = 0;
  int whiteScore = 0;
  String gameResult = '';

  @override
  void initState() {
    super.initState();
    _initializeBoard();
    _calculateScores();
  }

  void _initializeBoard() {
    board = List.generate(
      boardSize,
      (i) => List.generate(boardSize, (j) => 0),
    );
    
    // 初期配置
    int center = boardSize ~/ 2;
    board[center - 1][center - 1] = 2; // 白
    board[center - 1][center] = 1;     // 黒
    board[center][center - 1] = 1;     // 黒
    board[center][center] = 2;         // 白
  }

  void _calculateScores() {
    blackScore = 0;
    whiteScore = 0;
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] == 1) {
          blackScore++;
        } else if (board[i][j] == 2) {
          whiteScore++;
        }
      }
    }
  }

  bool _isValidMove(int row, int col, int player) {
    if (board[row][col] != 0) return false;

    final directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1],
    ];

    for (final direction in directions) {
      if (_canFlip(row, col, direction[0], direction[1], player)) {
        return true;
      }
    }
    return false;
  }

  bool _canFlip(int row, int col, int dRow, int dCol, int player) {
    int opponent = player == 1 ? 2 : 1;
    int r = row + dRow;
    int c = col + dCol;
    bool hasOpponent = false;

    while (r >= 0 && r < boardSize && c >= 0 && c < boardSize) {
      if (board[r][c] == opponent) {
        hasOpponent = true;
      } else if (board[r][c] == player) {
        return hasOpponent;
      } else {
        break;
      }
      r += dRow;
      c += dCol;
    }
    return false;
  }

  void _makeMove(int row, int col) {
    if (!_isValidMove(row, col, currentPlayer)) return;

    board[row][col] = currentPlayer;
    _flipPieces(row, col, currentPlayer);
    _calculateScores();

    // 次のプレイヤーに交代
    currentPlayer = currentPlayer == 1 ? 2 : 1;

    // NPCの場合はAIの手番
    if (widget.isNPC && currentPlayer == 2 && !gameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _makeAIMove();
      });
    }

    // ゲーム終了チェック
    _checkGameOver();
  }

  void _flipPieces(int row, int col, int player) {
    final directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1],
    ];

    for (final direction in directions) {
      if (_canFlip(row, col, direction[0], direction[1], player)) {
        _flipInDirection(row, col, direction[0], direction[1], player);
      }
    }
  }

  void _flipInDirection(int row, int col, int dRow, int dCol, int player) {
    int opponent = player == 1 ? 2 : 1;
    int r = row + dRow;
    int c = col + dCol;

    while (r >= 0 && r < boardSize && c >= 0 && c < boardSize) {
      if (board[r][c] == opponent) {
        board[r][c] = player;
      } else {
        break;
      }
      r += dRow;
      c += dCol;
    }
  }

  void _makeAIMove() {
    List<List<int>> validMoves = [];
    
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (_isValidMove(i, j, currentPlayer)) {
          validMoves.add([i, j]);
        }
      }
    }

    if (validMoves.isNotEmpty) {
      List<int> bestMove;
      
      switch (widget.difficulty) {
        case 1: // 初級: ランダム
          bestMove = validMoves[Random().nextInt(validMoves.length)];
          break;
        case 2: // 中級: 貪欲法
          bestMove = _findGreedyMove(validMoves);
          break;
        case 3: // 上級: ミニマックス
          bestMove = _findMinimaxMove(validMoves);
          break;
        default:
          bestMove = validMoves[0];
      }
      
      _makeMove(bestMove[0], bestMove[1]);
    }
  }

  List<int> _findGreedyMove(List<List<int>> validMoves) {
    List<int> bestMove = validMoves[0];
    int maxFlips = 0;

    for (final move in validMoves) {
      int flips = _countFlips(move[0], move[1], currentPlayer);
      if (flips > maxFlips) {
        maxFlips = flips;
        bestMove = move;
      }
    }

    return bestMove;
  }

  List<int> _findMinimaxMove(List<List<int>> validMoves) {
    List<int> bestMove = validMoves[0];
    int bestScore = -1000;

    for (final move in validMoves) {
      List<List<int>> tempBoard = _copyBoard();
      _makeTempMove(tempBoard, move[0], move[1], currentPlayer);
      int score = _minimax(tempBoard, 3, false, -1000, 1000);
      
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  int _countFlips(int row, int col, int player) {
    int totalFlips = 0;
    final directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1],
    ];

    for (final direction in directions) {
      if (_canFlip(row, col, direction[0], direction[1], player)) {
        totalFlips += _countFlipsInDirection(row, col, direction[0], direction[1], player);
      }
    }

    return totalFlips;
  }

  int _countFlipsInDirection(int row, int col, int dRow, int dCol, int player) {
    int opponent = player == 1 ? 2 : 1;
    int r = row + dRow;
    int c = col + dCol;
    int count = 0;

    while (r >= 0 && r < boardSize && c >= 0 && c < boardSize) {
      if (board[r][c] == opponent) {
        count++;
      } else {
        break;
      }
      r += dRow;
      c += dCol;
    }

    return count;
  }

  List<List<int>> _copyBoard() {
    return List.generate(
      boardSize,
      (i) => List.generate(boardSize, (j) => board[i][j]),
    );
  }

  void _makeTempMove(List<List<int>> tempBoard, int row, int col, int player) {
    tempBoard[row][col] = player;
    _flipPiecesOnBoard(tempBoard, row, col, player);
  }

  void _flipPiecesOnBoard(List<List<int>> tempBoard, int row, int col, int player) {
    final directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1],
    ];

    for (final direction in directions) {
      if (_canFlipOnBoard(tempBoard, row, col, direction[0], direction[1], player)) {
        _flipInDirectionOnBoard(tempBoard, row, col, direction[0], direction[1], player);
      }
    }
  }

  bool _canFlipOnBoard(List<List<int>> tempBoard, int row, int col, int dRow, int dCol, int player) {
    int opponent = player == 1 ? 2 : 1;
    int r = row + dRow;
    int c = col + dCol;
    bool hasOpponent = false;

    while (r >= 0 && r < boardSize && c >= 0 && c < boardSize) {
      if (tempBoard[r][c] == opponent) {
        hasOpponent = true;
      } else if (tempBoard[r][c] == player) {
        return hasOpponent;
      } else {
        break;
      }
      r += dRow;
      c += dCol;
    }
    return false;
  }

  void _flipInDirectionOnBoard(List<List<int>> tempBoard, int row, int col, int dRow, int dCol, int player) {
    int opponent = player == 1 ? 2 : 1;
    int r = row + dRow;
    int c = col + dCol;

    while (r >= 0 && r < boardSize && c >= 0 && c < boardSize) {
      if (tempBoard[r][c] == opponent) {
        tempBoard[r][c] = player;
      } else {
        break;
      }
      r += dRow;
      c += dCol;
    }
  }

  int _minimax(List<List<int>> tempBoard, int depth, bool isMaximizing, int alpha, int beta) {
    if (depth == 0) {
      return _evaluateBoard(tempBoard);
    }

    List<List<int>> validMoves = _getValidMoves(tempBoard, isMaximizing ? 2 : 1);

    if (validMoves.isEmpty) {
      return _evaluateBoard(tempBoard);
    }

    if (isMaximizing) {
      int maxScore = -1000;
      for (final move in validMoves) {
        List<List<int>> newBoard = _copyBoard();
        _makeTempMove(newBoard, move[0], move[1], 2);
        int score = _minimax(newBoard, depth - 1, false, alpha, beta);
        maxScore = max(maxScore, score);
        alpha = max(alpha, score);
        if (beta <= alpha) break;
      }
      return maxScore;
    } else {
      int minScore = 1000;
      for (final move in validMoves) {
        List<List<int>> newBoard = _copyBoard();
        _makeTempMove(newBoard, move[0], move[1], 1);
        int score = _minimax(newBoard, depth - 1, true, alpha, beta);
        minScore = min(minScore, score);
        beta = min(beta, score);
        if (beta <= alpha) break;
      }
      return minScore;
    }
  }

  List<List<int>> _getValidMoves(List<List<int>> tempBoard, int player) {
    List<List<int>> validMoves = [];
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (_isValidMoveOnBoard(tempBoard, i, j, player)) {
          validMoves.add([i, j]);
        }
      }
    }
    return validMoves;
  }

  bool _isValidMoveOnBoard(List<List<int>> tempBoard, int row, int col, int player) {
    if (tempBoard[row][col] != 0) return false;

    final directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1],
    ];

    for (final direction in directions) {
      if (_canFlipOnBoard(tempBoard, row, col, direction[0], direction[1], player)) {
        return true;
      }
    }
    return false;
  }

  int _evaluateBoard(List<List<int>> tempBoard) {
    int blackCount = 0;
    int whiteCount = 0;

    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (tempBoard[i][j] == 1) {
          blackCount++;
        } else if (tempBoard[i][j] == 2) {
          whiteCount++;
        }
      }
    }

    return whiteCount - blackCount; // AIは白なので、白が多いほど良い
  }

  void _checkGameOver() {
    bool hasValidMoves = false;
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (_isValidMove(i, j, currentPlayer)) {
          hasValidMoves = true;
          break;
        }
      }
      if (hasValidMoves) break;
    }

    if (!hasValidMoves) {
      // パスの場合、相手の手番をチェック
      int nextPlayer = currentPlayer == 1 ? 2 : 1;
      bool nextPlayerHasValidMoves = false;
      
      for (int i = 0; i < boardSize; i++) {
        for (int j = 0; j < boardSize; j++) {
          if (_isValidMove(i, j, nextPlayer)) {
            nextPlayerHasValidMoves = true;
            break;
          }
        }
        if (nextPlayerHasValidMoves) break;
      }

      if (!nextPlayerHasValidMoves) {
        // ゲーム終了
        gameOver = true;
        _calculateScores();
        _determineWinner();
      } else {
        // パス
        currentPlayer = nextPlayer;
        if (widget.isNPC && currentPlayer == 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _makeAIMove();
          });
        }
      }
    }
  }

  void _determineWinner() {
    if (blackScore > whiteScore) {
      gameResult = '黒の勝ち！';
    } else if (whiteScore > blackScore) {
      gameResult = '白の勝ち！';
    } else {
      gameResult = '引き分け！';
    }
    
    // ゲーム終了時にランキングを保存
    _saveGameResult();
  }

  void _saveGameResult() async {
    // プレイヤー名を取得（簡易版）
    String playerName = 'プレイヤー';
    // 勝者を判定
    bool playerWon = false;
    if (widget.isNPC) {
      // AI対戦の場合、プレイヤーは黒なので黒の勝ちがプレイヤーの勝ち
      playerWon = blackScore > whiteScore;
    } else {
      // 二人プレイの場合、黒の勝ちを記録
      playerWon = blackScore > whiteScore;
    }
    // スコアを決定（勝者のスコア）
    int finalScore = playerWon ? blackScore : whiteScore;
    final entry = RankingEntry(
      playerName: playerName,
      score: finalScore,
      difficulty: widget.difficulty,
      isNPC: widget.isNPC,
      date: DateTime.now(),
      playerWon: playerWon,
    );
    // ローカルランキングに保存
    await RankingManager.saveLocalRanking(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNPC ? 'NPC対戦 (難易度: ${widget.difficulty})' : '二人プレイ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // スコア表示
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildScoreCard('黒', blackScore, Colors.black),
                _buildScoreCard('白', whiteScore, Colors.white),
              ],
            ),
          ),
          
          // ゲームボード
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (gameOver)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Text(
                          gameResult,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    
                    // ボード
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.brown, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: List.generate(boardSize, (i) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(boardSize, (j) {
                              return GestureDetector(
                                onTap: () {
                                  if (!gameOver && _isValidMove(i, j, currentPlayer)) {
                                    setState(() {
                                      _makeMove(i, j);
                                    });
                                  }
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getCellColor(i, j),
                                    border: Border.all(color: Colors.brown),
                                  ),
                                  child: _buildPiece(i, j),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 現在のプレイヤー表示
                    if (!gameOver)
                      Text(
                        '現在のプレイヤー: ${currentPlayer == 1 ? "黒" : "白"}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // リセットボタン
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _initializeBoard();
                          currentPlayer = 1;
                          gameOver = false;
                          gameResult = '';
                          _calculateScores();
                        });
                      },
                      child: const Text('リセット'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String player, int score, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            player,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            score.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCellColor(int row, int col) {
    if (_isValidMove(row, col, currentPlayer)) {
      return Colors.green.withOpacity(0.3);
    }
    return Colors.green.shade100;
  }

  Widget _buildPiece(int row, int col) {
    if (board[row][col] == 0) {
      return Container();
    }
    
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: board[row][col] == 1 ? Colors.black : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
      ),
    );
  }
} 