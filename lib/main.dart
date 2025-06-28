import 'package:flutter/material.dart';

void main() {
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
              'コンピュータと対戦',
              Icons.computer,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OthelloGame(isNPC: true),
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

class OthelloGame extends StatefulWidget {
  final bool isNPC;
  
  const OthelloGame({super.key, required this.isNPC});

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
      // 最も多くの石を取れる手を選択（貪欲法）
      List<int> bestMove = validMoves[0];
      int maxFlips = 0;
      
      for (var move in validMoves) {
        int flips = countFlips(move[0], move[1]);
        if (flips > maxFlips) {
          maxFlips = flips;
          bestMove = move;
        }
      }
      
      setState(() {
        makeMove(bestMove[0], bestMove[1]);
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNPC ? 'オセロゲーム (NPC対戦)' : 'オセロゲーム (二人プレイ)'),
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
