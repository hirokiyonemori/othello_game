import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  ]);
  
  // AdMob初期化
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
    await AdManager.loadRewardedAd();
  }
  
  runApp(const OthelloApp());
}

class OthelloApp extends StatelessWidget {
  const OthelloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'シンプルオセロ',
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
          builder: (context) => const OthelloGame(isNPC: false, playerColor: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('シンプルオセロ'),
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
  int _selectedDifficulty = 1;
  int _handicapLevel = 0;
  int _selectedPlayer = 1; // 1: 黒（先手）, 2: 白（後手）

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('難易度・ハンデ選択'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              '難易度を選択してください',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // ハンデキャップ選択
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ハンデキャップ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _buildHandicapChip('なし', 0, Colors.grey),
                        _buildHandicapChip('レベル1', 1, Colors.blue),
                        _buildHandicapChip('レベル2', 2, Colors.orange),
                        _buildHandicapChip('レベル3', 3, Colors.red),
                        _buildHandicapChip('レベル4', 4, Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // プレイヤー選択
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'プレイヤー選択',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: _buildPlayerChip('黒（先手）', 1, Colors.black),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: _buildPlayerChip('白（後手）', 2, Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 難易度選択（10段階）
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5, // ボタンを大きく
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: 10,
              itemBuilder: (context, index) {
                return _buildDifficultyCard(context, index + 1);
              },
            ),
            const SizedBox(height: 16),
            
            // 説明テキスト
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'ハンデキャップ説明',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getHandicapDescription(_handicapLevel),
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // ゲーム開始ボタン
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OthelloGame(
                        isNPC: true,
                        difficulty: _selectedDifficulty,
                        handicapLevel: _handicapLevel,
                        playerColor: _selectedPlayer, // プレイヤーの色を渡す
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'ゲーム開始',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16), // 下部に余白を追加
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(BuildContext context, int difficulty) {
    final isSelected = _selectedDifficulty == difficulty;
    final info = _getDifficultyInfo(difficulty);
    return Card(
      elevation: isSelected ? 3 : 1,
      color: isSelected ? info.color.withOpacity(0.2) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isSelected ? info.color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          setState(() {
            _selectedDifficulty = difficulty;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0), // 余白も少し増やす
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'レベル$difficulty',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: info.color,
                  fontSize: 18,
                ),
              ),
              Text(
                info.name,
                style: TextStyle(
                  color: info.color,
                  fontSize: 14,
                ),
              ),
              Text(
                info.description,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _DifficultyInfo _getDifficultyInfo(int difficulty) {
    switch (difficulty) {
      case 1:
        return _DifficultyInfo('超初心者', 'ランダムに手を選択', Colors.green);
      case 2:
        return _DifficultyInfo('初心者', '時々良い手を選択', Colors.lightGreen);
      case 3:
        return _DifficultyInfo('初級', '基本的な戦略', Colors.blue);
      case 4:
        return _DifficultyInfo('初級+', '少し賢い選択', Colors.lightBlue);
      case 5:
        return _DifficultyInfo('中級', 'バランスの取れた戦略', Colors.orange);
      case 6:
        return _DifficultyInfo('中級+', 'より良い手を選択', Colors.deepOrange);
      case 7:
        return _DifficultyInfo('上級', '高度な戦略', Colors.purple);
      case 8:
        return _DifficultyInfo('上級+', '非常に良い手を選択', Colors.deepPurple);
      case 9:
        return _DifficultyInfo('エキスパート', '最適に近い選択', Colors.red);
      case 10:
        return _DifficultyInfo('マスター', 'ほぼ最適な選択', Colors.redAccent);
      default:
        return _DifficultyInfo('初級', '基本的な戦略', Colors.blue);
    }
  }

  Widget _buildHandicapChip(String title, int level, Color color) {
    final isSelected = _handicapLevel == level;
    return FilterChip(
      label: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _handicapLevel = level;
        });
      },
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(color: color),
    );
  }

  Widget _buildPlayerChip(String title, int player, Color color) {
    final isSelected = _selectedPlayer == player;
    return FilterChip(
      label: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: color == Colors.white ? Colors.grey : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPlayer = player;
        });
      },
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color == Colors.white ? Colors.grey : color,
      checkmarkColor: Colors.white,
      side: BorderSide(color: color),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  String _getHandicapDescription(int level) {
    switch (level) {
      case 0:
        return 'ハンデキャップなし。通常の対戦です。';
      case 1:
        return 'プレイヤーが先手になります。';
      case 2:
        return 'プレイヤーが先手で、AIの思考時間が少し長くなります。';
      case 3:
        return 'プレイヤーが先手で、AIの難易度が1段階下がります。';
      case 4:
        return 'プレイヤーが先手で、角に黒のコマが初期配置されます。';
      default:
        return 'ハンデキャップなし。通常の対戦です。';
    }
  }
}

class _DifficultyInfo {
  final String name;
  final String description;
  final Color color;
  _DifficultyInfo(this.name, this.description, this.color);
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
    return SingleChildScrollView(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _localRankings.length,
        itemBuilder: (context, index) {
          final entry = _localRankings[index];
          return _buildRankingCard(entry, index + 1);
        },
      ),
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
  final int handicapLevel;
  final int playerColor; // 1: 黒（先手）, 2: 白（後手）

  const OthelloGame({
    super.key,
    required this.isNPC,
    this.difficulty = 1,
    this.handicapLevel = 0,
    this.playerColor = 1, // デフォルトは黒（先手）
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
  
  // ヒント機能用の状態管理
  bool _hintEnabled = false;
  int? _hintRow;
  int? _hintCol;
  
  // NPCの手の視認性向上用
  int? _lastMoveRow;
  int? _lastMoveCol;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
    _calculateScores();
    
    // プレイヤーの色に基づいて初期設定
    if (widget.playerColor == 2) {
      // プレイヤーが白（後手）の場合、NPC（黒）が先手
      currentPlayer = 1; // 黒（NPC）が先手
    } else {
      // プレイヤーが黒（先手）の場合
      currentPlayer = 1; // 黒（プレイヤー）が先手
    }
    
    // ハンデキャップレベル1以上の場合、プレイヤー（黒）を先手にする
    if (widget.handicapLevel >= 1) {
      currentPlayer = 1; // 黒が先手
    }
    
    // プレイヤーが白（後手）の場合、NPCが先手なのでAIの手番を開始
    if (widget.isNPC && widget.playerColor == 2 && currentPlayer != widget.playerColor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _makeAIMove();
      });
    }
  }

  @override
  void dispose() {
    AdManager.dispose();
    super.dispose();
  }

  void _initializeBoard() {
    board = List.generate(
      boardSize,
      (i) => List.generate(boardSize, (j) => 0),
    );
    
    // 基本の初期配置
    int center = boardSize ~/ 2;
    board[center - 1][center - 1] = 2; // 白
    board[center - 1][center] = 1;     // 黒
    board[center][center - 1] = 1;     // 黒
    board[center][center] = 2;         // 白
    
    // ハンデキャップレベル4の場合、角に黒のコマを配置
    if (widget.handicapLevel == 4) {
      board[0][0] = 1; // 左上角
      board[0][boardSize - 1] = 1; // 右上角
      board[boardSize - 1][0] = 1; // 左下角
      board[boardSize - 1][boardSize - 1] = 1; // 右下角
    }
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

    // ヒント状態をリセット
    _hintEnabled = false;
    _hintRow = null;
    _hintCol = null;

    board[row][col] = currentPlayer;
    _flipPieces(row, col, currentPlayer);
    _calculateScores();

    // 次のプレイヤーに交代
    currentPlayer = currentPlayer == 1 ? 2 : 1;

    // ゲーム終了チェック
    _checkGameOver();

    // NPCの場合はAIの手番（ゲーム終了チェック後）
    if (widget.isNPC && currentPlayer != widget.playerColor && !gameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _makeAIMove();
      });
    }
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
      
      // ハンデキャップレベルに応じてAI難易度を調整
      int adjustedDifficulty = _getAdjustedDifficulty();
      
      switch (adjustedDifficulty) {
        case 1: // 超初心者: ランダム
          bestMove = validMoves[Random().nextInt(validMoves.length)];
          break;
        case 2: // 初心者: 時々良い手を選択
          bestMove = _selectMoveByDifficulty(validMoves, 0.8);
          break;
        case 3: // 初級: 基本的な戦略
          bestMove = _findGreedyMove(validMoves);
          break;
        case 4: // 初級+: 少し賢い選択
          bestMove = _selectMoveByDifficulty(validMoves, 0.6);
          break;
        case 5: // 中級: バランスの取れた戦略
          bestMove = _findBalancedMove(validMoves);
          break;
        case 6: // 中級+: より良い手を選択
          bestMove = _selectMoveByDifficulty(validMoves, 0.4);
          break;
        case 7: // 上級: 高度な戦略
          bestMove = _findAdvancedMove(validMoves);
          break;
        case 8: // 上級+: 非常に良い手を選択
          bestMove = _selectMoveByDifficulty(validMoves, 0.2);
          break;
        case 9: // エキスパート: 最適に近い選択
          bestMove = _findMinimaxMove(validMoves);
          break;
        case 10: // マスター: ほぼ最適な選択
          bestMove = _findMinimaxMove(validMoves);
          break;
        default:
          bestMove = validMoves[0];
      }
      
      // NPCの思考時間を1.5秒に延長（視認性向上）
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _makeMove(bestMove[0], bestMove[1]);
            // NPCが置いた場所をハイライト
            _lastMoveRow = bestMove[0];
            _lastMoveCol = bestMove[1];
          });
          
          // 3秒後にハイライトを消す
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _lastMoveRow = null;
                _lastMoveCol = null;
              });
            }
          });
        }
      });
    }
  }

  int _getAdjustedDifficulty() {
    int baseDifficulty = widget.difficulty;
    
    // ハンデキャップレベル3の場合、AI難易度を1段階下げる
    if (widget.handicapLevel == 3) {
      return (baseDifficulty - 1).clamp(1, 10);
    }
    
    return baseDifficulty;
  }

  List<int> _selectMoveByDifficulty(List<List<int>> validMoves, double randomChance) {
    if (Random().nextDouble() < randomChance) {
      // ランダム選択
      return validMoves[Random().nextInt(validMoves.length)];
    } else {
      // 戦略的選択
      return _findGreedyMove(validMoves);
    }
  }

  List<int> _findBalancedMove(List<List<int>> validMoves) {
    List<int> bestMove = validMoves[0];
    double bestScore = -1000;

    for (final move in validMoves) {
      double score = _evaluateMove(move[0], move[1], currentPlayer);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  List<int> _findAdvancedMove(List<List<int>> validMoves) {
    List<int> bestMove = validMoves[0];
    int bestScore = -1000;

    for (final move in validMoves) {
      List<List<int>> tempBoard = _copyBoard();
      _makeTempMove(tempBoard, move[0], move[1], currentPlayer);
      int score = _minimax(tempBoard, 2, false, -1000, 1000);
      
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  double _evaluateMove(int row, int col, int player) {
    double score = 0.0;
    
    // 1. 取れる石の数（基本スコア）
    score += _countFlips(row, col, player) * 10;
    
    // 2. 位置によるボーナス
    score += _getPositionBonus(row, col);
    
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
        if (widget.isNPC && currentPlayer == 2 && !gameOver) {
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
        title: Text(
          widget.isNPC 
            ? 'NPC対戦 (難易度: ${widget.difficulty}${widget.handicapLevel > 0 ? ', ハンデ: ${widget.handicapLevel}' : ''})' 
            : '二人プレイ'
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // スコア表示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
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
              gameOver ? gameResult : _getCurrentPlayerText(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          
          // オセロボード
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 利用可能なスペースに基づいてボードサイズを計算
                double availableSize = constraints.maxWidth < constraints.maxHeight 
                    ? constraints.maxWidth 
                    : constraints.maxHeight;
                double boardSize = availableSize - 32; // マージンを引く
                
                return Center(
                  child: Container(
                    width: boardSize,
                    height: boardSize,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown, width: 2),
                      color: Colors.green[800],
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                      ),
                      itemCount: 64,
                      itemBuilder: (context, index) {
                        int row = index ~/ 8;
                        int col = index % 8;
                        return _buildCell(row, col);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          
          // ボタンエリア
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _showResetDialog(),
                  child: const Text('リセット'),
                ),
                if (widget.isNPC) // NPC対戦時のみヒントボタンを表示
                  SizedBox(
                    width: 120, // ボタン幅を広げる
                    child: ElevatedButton(
                      onPressed: _showHintAd, // 常にヒントを見れるようにする
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hintEnabled ? Colors.orange : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      child: Text(
                        _hintEnabled ? 'ヒント表示中' : 'ヒントを見る\n（広告）',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        softWrap: true,
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ホーム'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String player, int score, Color color) {
    // 白の場合は背景色とテキスト色を調整して見やすくする
    Color backgroundColor = color == Colors.white 
        ? Colors.grey[100]! 
        : color.withOpacity(0.1);
    Color textColor = color == Colors.white 
        ? Colors.black 
        : color;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            player,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    int cellValue = board[row][col];
    bool isValid = _isValidMove(row, col, currentPlayer);
    bool isLastMove = _lastMoveRow == row && _lastMoveCol == col;
    bool isHintMove = _hintEnabled && _hintRow == row && _hintCol == col;
    
    return GestureDetector(
      onTap: () {
        if (!gameOver && (widget.isNPC ? currentPlayer == widget.playerColor : true) && _isValidMove(row, col, currentPlayer)) {
          setState(() {
            _makeMove(row, col);
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isLastMove ? Colors.red : (isHintMove ? Colors.orange : Colors.brown),
            width: isLastMove ? 3 : (isHintMove ? 2 : 1),
          ),
          color: isValid ? Colors.green[600] : Colors.green[800],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (cellValue == 0 && isValid)
              _buildHintDot(),
            if (cellValue != 0)
              _buildStone(cellValue),
            if (_hintEnabled && _hintRow == row && _hintCol == col && cellValue == 0)
              Icon(Icons.lightbulb, color: Colors.orange, size: 32),
          ],
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

  // 現在のプレイヤーテキストを取得
  String _getCurrentPlayerText() {
    if (widget.isNPC) {
      if (currentPlayer == widget.playerColor) {
        return 'あなたの番（${widget.playerColor == 1 ? "黒" : "白"}）';
      } else {
        return 'NPCの番（${widget.playerColor == 1 ? "白" : "黒"}）';
      }
    } else {
      return '現在のプレイヤー: ${currentPlayer == 1 ? "黒" : "白"}';
    }
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

  // ヒント機能のメソッド
  void _showHintAd() async {
    // 既にヒントが表示中の場合は、新しいヒントで上書き
    if (_hintEnabled) {
      setState(() {
        _hintEnabled = false;
        _hintRow = null;
        _hintCol = null;
      });
    }
    
    // リワード広告が準備できていない場合は読み込み
    if (!AdManager.isRewardedAdReady) {
      await AdManager.loadRewardedAd();
    }
    
    // リワード広告を表示
    bool rewardEarned = await AdManager.showRewardedAd();
    
    // デバッグ用：広告視聴結果をログ出力
    print('Reward earned: $rewardEarned');
    print('Showing hint after ad completion');
    
    // 広告視聴完了後（成功・失敗に関わらず）ヒントを表示
    if (mounted) {
      setState(() {
        _hintEnabled = true;
        // 現在のプレイヤーの最適手を計算
        _calculateOptimalMove();
      });
      
      // ヒントを20秒間表示（広告が閉じられた直後から開始）
      Future.delayed(const Duration(seconds: 20), () {
        if (mounted) {
          setState(() {
            _hintEnabled = false;
            _hintRow = null;
            _hintCol = null;
          });
          print('Hint hidden after 20 seconds');
        }
      });
    }
  }
  
  // 最適手を計算
  void _calculateOptimalMove() {
    List<List<int>> validMoves = [];
    
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (_isValidMove(i, j, currentPlayer)) {
          validMoves.add([i, j]);
        }
      }
    }
    
    if (validMoves.isNotEmpty) {
      // 現在のAIロジックを使って最適手を計算
      List<int> bestMove = _findBestMoveForHint(validMoves);
      _hintRow = bestMove[0];
      _hintCol = bestMove[1];
    }
  }
  
  // ヒント用の最適手計算
  List<int> _findBestMoveForHint(List<List<int>> validMoves) {
    // 現在の難易度に応じたAIロジックを使用
    int adjustedDifficulty = _getAdjustedDifficulty();
    
    switch (adjustedDifficulty) {
      case 1:
        return validMoves[Random().nextInt(validMoves.length)];
      case 2:
        return _selectMoveByDifficulty(validMoves, 0.8);
      case 3:
        return _findGreedyMove(validMoves);
      case 4:
        return _selectMoveByDifficulty(validMoves, 0.6);
      case 5:
        return _findBalancedMove(validMoves);
      case 6:
        return _selectMoveByDifficulty(validMoves, 0.4);
      case 7:
        return _findAdvancedMove(validMoves);
      case 8:
        return _selectMoveByDifficulty(validMoves, 0.2);
      case 9:
      case 10:
        return _findMinimaxMove(validMoves);
      default:
        return validMoves[0];
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲームをリセットしますか？'),
        content: const Text('この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _initializeBoard();
                currentPlayer = 1;
                gameOver = false;
                gameResult = '';
                _calculateScores();
                // リセット時にヒント状態もクリア
                _hintEnabled = false;
                _hintRow = null;
                _hintCol = null;
                _lastMoveRow = null;
                _lastMoveCol = null;
              });
              // リセット時にリワード広告を表示
              if (!kIsWeb) {
                await AdManager.showRewardedAd();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('リセット', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 