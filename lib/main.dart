import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const GameModeSelection(),
    );
  }
}

class GameModeSelection extends StatelessWidget {
  const GameModeSelection({super.key});

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
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OthelloGame(isNPC: false),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildModeButton(
              context,
              'NPCプレイ',
              'AIと対戦（難易度選択）',
              Icons.computer,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DifficultySelection(),
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
      height: 120,
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
            Icon(icon, size: 40),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DifficultySelection extends StatelessWidget {
  const DifficultySelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI難易度選択'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'AIの難易度を選択してください',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 10,
                itemBuilder: (context, index) {
                  return _buildDifficultyCard(context, index + 1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(BuildContext context, int difficulty) {
    final difficultyInfo = _getDifficultyInfo(difficulty);
    
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OthelloGame(isNPC: true, difficulty: difficulty),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: difficultyInfo.colors,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'レベル $difficulty',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  difficultyInfo.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  difficultyInfo.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DifficultyInfo _getDifficultyInfo(int difficulty) {
    switch (difficulty) {
      case 1:
        return DifficultyInfo(
          '超初心者',
          'ランダムに手を選択',
          [Colors.green, Colors.lightGreen],
        );
      case 2:
        return DifficultyInfo(
          '初心者',
          '時々良い手を選択',
          [Colors.lightGreen, Colors.green],
        );
      case 3:
        return DifficultyInfo(
          '初級',
          '基本的な戦略',
          [Colors.blue, Colors.lightBlue],
        );
      case 4:
        return DifficultyInfo(
          '初級+',
          '少し賢い選択',
          [Colors.lightBlue, Colors.blue],
        );
      case 5:
        return DifficultyInfo(
          '中級',
          'バランスの取れた戦略',
          [Colors.orange, Colors.deepOrange],
        );
      case 6:
        return DifficultyInfo(
          '中級+',
          'より良い手を選択',
          [Colors.deepOrange, Colors.orange],
        );
      case 7:
        return DifficultyInfo(
          '上級',
          '高度な戦略',
          [Colors.purple, Colors.deepPurple],
        );
      case 8:
        return DifficultyInfo(
          '上級+',
          '非常に良い手を選択',
          [Colors.deepPurple, Colors.purple],
        );
      case 9:
        return DifficultyInfo(
          'エキスパート',
          '最適に近い選択',
          [Colors.red, Colors.red[900]!],
        );
      case 10:
        return DifficultyInfo(
          'マスター',
          'ほぼ最適な選択',
          [Colors.red[900]!, Colors.red],
        );
      default:
        return DifficultyInfo(
          '初級',
          '基本的な戦略',
          [Colors.blue, Colors.lightBlue],
        );
    }
  }
}

class DifficultyInfo {
  final String name;
  final String description;
  final List<Color> colors;

  DifficultyInfo(this.name, this.description, this.colors);
}

class OthelloGame extends StatefulWidget {
  final bool isNPC;
  final int difficulty;
  
  const OthelloGame({
    super.key, 
    required this.isNPC, 
    this.difficulty = 5,
  });

  @override
  State<OthelloGame> createState() => _OthelloGameState();
}

class _OthelloGameState extends State<OthelloGame> {
  static const int boardSize = 8;
  List<List<int>> board = List.generate(
    boardSize,
    (i) => List.generate(boardSize, (j) => 0),
  );
  
  int currentPlayer = 1; // 1: 黒, 2: 白
  int blackScore = 0;
  int whiteScore = 0;
  bool gameOver = false;
  String winner = '';
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    initializeBoard();
    updateScores();
  }

  void initializeBoard() {
    // 初期配置
    board[3][3] = 2; // 白
    board[3][4] = 1; // 黒
    board[4][3] = 1; // 黒
    board[4][4] = 2; // 白
  }

  void updateScores() {
    blackScore = 0;
    whiteScore = 0;
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] == 1) blackScore++;
        if (board[i][j] == 2) whiteScore++;
      }
    }
  }

  bool isValidMove(int row, int col) {
    if (board[row][col] != 0) return false;
    
    List<List<int>> directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1]
    ];

    for (var direction in directions) {
      if (canFlip(row, col, direction[0], direction[1])) {
        return true;
      }
    }
    return false;
  }

  bool canFlip(int row, int col, int dRow, int dCol) {
    int newRow = row + dRow;
    int newCol = col + dCol;
    
    if (newRow < 0 || newRow >= boardSize || newCol < 0 || newCol >= boardSize) {
      return false;
    }
    
    if (board[newRow][newCol] != (currentPlayer == 1 ? 2 : 1)) {
      return false;
    }
    
    newRow += dRow;
    newCol += dCol;
    
    while (newRow >= 0 && newRow < boardSize && newCol >= 0 && newCol < boardSize) {
      if (board[newRow][newCol] == 0) return false;
      if (board[newRow][newCol] == currentPlayer) return true;
      newRow += dRow;
      newCol += dCol;
    }
    
    return false;
  }

  void makeMove(int row, int col) {
    if (!isValidMove(row, col)) return;
    
    List<List<int>> directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1]
    ];

    board[row][col] = currentPlayer;
    
    for (var direction in directions) {
      flipStones(row, col, direction[0], direction[1]);
    }
    
    currentPlayer = currentPlayer == 1 ? 2 : 1;
    updateScores();
    
    // ゲーム終了チェック
    if (!hasValidMoves()) {
      if (!hasValidMoves()) {
        gameOver = true;
        if (blackScore > whiteScore) {
          winner = '黒の勝ち！';
        } else if (whiteScore > blackScore) {
          winner = '白の勝ち！';
        } else {
          winner = '引き分け！';
        }
      }
    }
    
    // NPCプレイの場合、NPCの手番を実行
    if (widget.isNPC && currentPlayer == 2 && !gameOver) {
      Future.delayed(const Duration(milliseconds: 500), () {
        makeNPCMove();
      });
    }
  }

  void makeNPCMove() {
    if (gameOver) return;
    
    List<List<int>> validMoves = [];
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (isValidMove(i, j)) {
          validMoves.add([i, j]);
        }
      }
    }
    
    if (validMoves.isNotEmpty) {
      List<int> selectedMove = selectMoveByDifficulty(validMoves);
      
      setState(() {
        makeMove(selectedMove[0], selectedMove[1]);
      });
    }
  }

  List<int> selectMoveByDifficulty(List<List<int>> validMoves) {
    if (validMoves.isEmpty) return [0, 0];
    
    // 難易度に応じた選択確率
    double randomChance = _getRandomChance();
    
    if (random.nextDouble() < randomChance) {
      // ランダム選択
      return validMoves[random.nextInt(validMoves.length)];
    } else {
      // 戦略的選択
      return _selectStrategicMove(validMoves);
    }
  }

  double _getRandomChance() {
    // 難易度が低いほどランダム選択の確率が高い
    switch (widget.difficulty) {
      case 1: return 0.95; // 95%ランダム
      case 2: return 0.85; // 85%ランダム
      case 3: return 0.70; // 70%ランダム
      case 4: return 0.55; // 55%ランダム
      case 5: return 0.40; // 40%ランダム
      case 6: return 0.25; // 25%ランダム
      case 7: return 0.15; // 15%ランダム
      case 8: return 0.08; // 8%ランダム
      case 9: return 0.03; // 3%ランダム
      case 10: return 0.01; // 1%ランダム
      default: return 0.40;
    }
  }

  List<int> _selectStrategicMove(List<List<int>> validMoves) {
    // 複数の戦略を組み合わせて選択
    List<MoveScore> scoredMoves = [];
    
    for (var move in validMoves) {
      double score = _calculateMoveScore(move[0], move[1]);
      scoredMoves.add(MoveScore(move, score));
    }
    
    // スコアでソート
    scoredMoves.sort((a, b) => b.score.compareTo(a.score));
    
    // 難易度に応じて上位の手から選択
    int selectionRange = _getSelectionRange();
    int selectedIndex = random.nextInt(
      scoredMoves.length > selectionRange ? selectionRange : scoredMoves.length
    );
    
    return scoredMoves[selectedIndex].move;
  }

  int _getSelectionRange() {
    // 難易度が高いほど良い手を選択
    switch (widget.difficulty) {
      case 1: return 10; // 上位10手からランダム
      case 2: return 8;
      case 3: return 6;
      case 4: return 5;
      case 5: return 4;
      case 6: return 3;
      case 7: return 2;
      case 8: return 2;
      case 9: return 1;
      case 10: return 1; // 最良の手のみ
      default: return 4;
    }
  }

  double _calculateMoveScore(int row, int col) {
    double score = 0.0;
    
    // 1. 取れる石の数（基本スコア）
    score += countFlips(row, col) * 10;
    
    // 2. 位置によるボーナス
    score += _getPositionBonus(row, col);
    
    // 3. 安定性ボーナス
    score += _getStabilityBonus(row, col);
    
    // 4. 機会ボーナス
    score += _getOpportunityBonus(row, col);
    
    return score;
  }

  double _getPositionBonus(int row, int col) {
    // 角は最高点
    if ((row == 0 || row == 7) && (col == 0 || col == 7)) {
      return 100;
    }
    
    // 端は高得点
    if (row == 0 || row == 7 || col == 0 || col == 7) {
      return 20;
    }
    
    // 内側は低得点
    if (row >= 2 && row <= 5 && col >= 2 && col <= 5) {
      return 5;
    }
    
    return 10;
  }

  double _getStabilityBonus(int row, int col) {
    // 取られた石が少ない手を優先
    double stability = 0;
    
    // 仮想的に石を置いてみる
    List<List<int>> tempBoard = List.generate(
      boardSize,
      (i) => List.from(board[i]),
    );
    
    tempBoard[row][col] = currentPlayer;
    
    // 取られる可能性を計算
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (tempBoard[i][j] == currentPlayer) {
          stability += _calculateStability(i, j);
        }
      }
    }
    
    return stability;
  }

  double _calculateStability(int row, int col) {
    // 角は安定
    if ((row == 0 || row == 7) && (col == 0 || col == 7)) {
      return 50;
    }
    
    // 端は比較的安定
    if (row == 0 || row == 7 || col == 0 || col == 7) {
      return 10;
    }
    
    return 1;
  }

  double _getOpportunityBonus(int row, int col) {
    // 相手の良い手を減らすボーナス
    double bonus = 0;
    
    // 仮想的に石を置いてみる
    List<List<int>> tempBoard = List.generate(
      boardSize,
      (i) => List.from(board[i]),
    );
    
    tempBoard[row][col] = currentPlayer;
    
    // 相手の有効な手の数を計算
    int opponentMoves = 0;
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (_isValidMoveForOpponent(tempBoard, i, j)) {
          opponentMoves++;
        }
      }
    }
    
    // 相手の手が少ないほどボーナス
    bonus += (64 - opponentMoves) * 0.5;
    
    return bonus;
  }

  bool _isValidMoveForOpponent(List<List<int>> tempBoard, int row, int col) {
    if (tempBoard[row][col] != 0) return false;
    
    List<List<int>> directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1]
    ];

    for (var direction in directions) {
      if (_canFlipForOpponent(tempBoard, row, col, direction[0], direction[1])) {
        return true;
      }
    }
    return false;
  }

  bool _canFlipForOpponent(List<List<int>> tempBoard, int row, int col, int dRow, int dCol) {
    int newRow = row + dRow;
    int newCol = col + dCol;
    
    if (newRow < 0 || newRow >= boardSize || newCol < 0 || newCol >= boardSize) {
      return false;
    }
    
    if (tempBoard[newRow][newCol] != currentPlayer) {
      return false;
    }
    
    newRow += dRow;
    newCol += dCol;
    
    while (newRow >= 0 && newRow < boardSize && newCol >= 0 && newCol < boardSize) {
      if (tempBoard[newRow][newCol] == 0) return false;
      if (tempBoard[newRow][newCol] == (currentPlayer == 1 ? 2 : 1)) return true;
      newRow += dRow;
      newCol += dCol;
    }
    
    return false;
  }

  int countFlips(int row, int col) {
    if (!isValidMove(row, col)) return 0;
    
    int totalFlips = 0;
    List<List<int>> directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1]
    ];

    for (var direction in directions) {
      totalFlips += countFlipsInDirection(row, col, direction[0], direction[1]);
    }
    
    return totalFlips;
  }

  int countFlipsInDirection(int row, int col, int dRow, int dCol) {
    if (!canFlip(row, col, dRow, dCol)) return 0;
    
    int flips = 0;
    int newRow = row + dRow;
    int newCol = col + dCol;
    
    while (board[newRow][newCol] != currentPlayer) {
      flips++;
      newRow += dRow;
      newCol += dCol;
    }
    
    return flips;
  }

  void flipStones(int row, int col, int dRow, int dCol) {
    if (!canFlip(row, col, dRow, dCol)) return;
    
    int newRow = row + dRow;
    int newCol = col + dCol;
    
    while (board[newRow][newCol] != currentPlayer) {
      board[newRow][newCol] = currentPlayer;
      newRow += dRow;
      newCol += dCol;
    }
  }

  bool hasValidMoves() {
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (isValidMove(i, j)) return true;
      }
    }
    return false;
  }

  void resetGame() {
    setState(() {
      board = List.generate(
        boardSize,
        (i) => List.generate(boardSize, (j) => 0),
      );
      currentPlayer = 1;
      gameOver = false;
      winner = '';
      initializeBoard();
      updateScores();
    });
  }

  String _getDifficultyName() {
    switch (widget.difficulty) {
      case 1: return '超初心者';
      case 2: return '初心者';
      case 3: return '初級';
      case 4: return '初級+';
      case 5: return '中級';
      case 6: return '中級+';
      case 7: return '上級';
      case 8: return '上級+';
      case 9: return 'エキスパート';
      case 10: return 'マスター';
      default: return '中級';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNPC 
          ? 'オセロゲーム (AI: ${_getDifficultyName()})' 
          : 'オセロゲーム (二人プレイ)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetGame,
            tooltip: 'リセット',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pop(context),
            tooltip: 'ホーム',
          ),
        ],
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
          
          // 現在のプレイヤー表示
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              gameOver ? winner : '現在のプレイヤー: ${currentPlayer == 1 ? "黒" : "白"}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          
          // オセロボード
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.brown, width: 2),
                  color: Colors.green[800],
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: boardSize,
                  ),
                  itemCount: boardSize * boardSize,
                  itemBuilder: (context, index) {
                    int row = index ~/ boardSize;
                    int col = index % boardSize;
                    return _buildCell(row, col);
                  },
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '$score',
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

  Widget _buildCell(int row, int col) {
    int cellValue = board[row][col];
    bool isValid = isValidMove(row, col);
    bool isNPCTurn = widget.isNPC && currentPlayer == 2;
    
    return GestureDetector(
      onTap: (gameOver || isNPCTurn) ? null : () {
        setState(() {
          makeMove(row, col);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.brown, width: 1),
          color: isValid ? Colors.green[600] : Colors.green[800],
        ),
        child: Center(
          child: cellValue == 0
              ? (isValid ? _buildHintDot() : null)
              : _buildStone(cellValue),
        ),
      ),
    );
  }

  Widget _buildStone(int player) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: player == 1 ? Colors.black : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: player == 1 ? Colors.grey[800]! : Colors.grey[400]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildHintDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.yellow.withOpacity(0.7),
        shape: BoxShape.circle,
      ),
    );
  }
}

class MoveScore {
  final List<int> move;
  final double score;

  MoveScore(this.move, this.score);
}
