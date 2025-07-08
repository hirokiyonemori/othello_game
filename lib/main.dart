import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_manager.dart';
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
  // AdMob初期化はそのまま
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
    await AdManager.checkAdFreeStatus();
    await AdManager.updateLaunchCount();
    
    // IDFA関連の情報をログ出力
    print('IDFA Support: ${AdManager.isIDFASupported}');
    print('IDFA Status: ${AdManager.getIDFAStatusDescription()}');
  }
  runApp(const OthelloApp());
}

class OthelloApp extends StatelessWidget {
  const OthelloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'オセロゲーム',
      debugShowCheckedModeBanner: false, // デバッグバナーを非表示
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
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    AdManager.loadRewardedAd();
    AdManager.loadInterstitialAd();
    
    // 2回目の起動時にインタースティシャル広告を表示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AdManager.shouldShowInterstitialOnLaunch && AdManager.isInterstitialAdReady) {
        AdManager.showInterstitialAd();
      }
    });
  }

  void _loadBannerAd() {
    if (AdManager.shouldShowAds) {
      _bannerAd = AdManager.createBannerAd();
      _bannerAd!.load().then((_) {
        setState(() {
          _isAdLoaded = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _navigateToGame(bool isNPC) {
    _navigateToGameScreen(isNPC);
  }

  void _navigateToGameScreen(bool isNPC) async {
    // ゲーム開始カウントを更新
    await AdManager.updateGameStartCount();
    // 5回目以降ならインタースティシャル広告を表示
    if (AdManager.shouldShowInterstitialOnGameStart && AdManager.isInterstitialAdReady) {
      await AdManager.showInterstitialAd();
    }
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
        actions: [
          if (AdManager.shouldShowAds)
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: _showRewardedAdDialog,
              tooltip: 'リワード広告を見て今日の広告を削除',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
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
          ),
          // Banner Ad
          if (AdManager.shouldShowAds && _isAdLoaded && _bannerAd != null)
            Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  void _showRewardedAdDialog() {
    if (!AdManager.shouldShowAds) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('リワード広告'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('リワード広告を見ると、今日は広告が表示されなくなります。'),
            SizedBox(height: 16),
            Text(
              '広告を見ますか？',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _showRewardedAd();
            },
            child: const Text('広告を見る'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRewardedAd() async {
    try {
      final rewardEarned = await AdManager.showRewardedAd();
      if (rewardEarned) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('今日は広告が表示されません！')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('広告の視聴に失敗しました。')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
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
                  childAspectRatio: 1.2,
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
            builder: (context) => TurnSelection(difficulty: difficulty),
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
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'レベル $difficulty',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    difficultyInfo.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    difficultyInfo.description,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
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

class TurnSelection extends StatefulWidget {
  final int difficulty;
  
  const TurnSelection({
    super.key,
    required this.difficulty,
  });

  @override
  State<TurnSelection> createState() => _TurnSelectionState();
}

class _TurnSelectionState extends State<TurnSelection> {
  bool _playerGoesFirst = true; // true: プレイヤー先手, false: AI先手

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('先手・後攻選択 (レベル${widget.difficulty})'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '先手・後攻を選択してください',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'どちらが先手になりますか？',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTurnOption(
                            title: 'プレイヤー先手',
                            subtitle: 'あなたが黒で先手',
                            icon: Icons.person,
                            color: Colors.black,
                            isSelected: _playerGoesFirst,
                            onTap: () => setState(() => _playerGoesFirst = true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTurnOption(
                            title: 'AI先手',
                            subtitle: 'AIが黒で先手',
                            icon: Icons.computer,
                            color: Colors.blue,
                            isSelected: !_playerGoesFirst,
                            onTap: () => setState(() => _playerGoesFirst = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OthelloGame(
                                isNPC: true,
                                difficulty: widget.difficulty,
                                playerGoesFirst: _playerGoesFirst,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'ゲーム開始',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? color.withOpacity(0.8) : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
  final bool playerGoesFirst; // true: プレイヤー先手, false: AI先手
  
  const OthelloGame({
    super.key, 
    required this.isNPC, 
    this.difficulty = 5,
    this.playerGoesFirst = true, // デフォルトはプレイヤー先手
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
  bool _showHintMode = false;
  List<int>? _hintMove; // 最善手ヒント

  @override
  void initState() {
    super.initState();
    initializeBoard();
    updateScores();
    
    // AIが先手の場合、最初の手番でAIが動く
    if (widget.isNPC && !widget.playerGoesFirst && currentPlayer == 1) {
      Future.delayed(const Duration(milliseconds: 500), () {
        makeNPCMove();
      });
    }
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
    // デバッグ用：スコアをコンソールに出力
    print('スコア更新 - 黒: $blackScore, 白: $whiteScore');
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
    
    // ヒントを消す
    _hintMove = null;
    
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
        
        // ゲーム終了時に広告を表示
        if (AdManager.shouldShowAds) {
          _showGameEndAds();
        }
      }
    }
    
    // NPCプレイの場合、NPCの手番を実行
    if (widget.isNPC && !gameOver) {
      bool isNPCTurn = (widget.playerGoesFirst && currentPlayer == 2) || 
                       (!widget.playerGoesFirst && currentPlayer == 1);
      if (isNPCTurn) {
        Future.delayed(const Duration(milliseconds: 500), () {
          makeNPCMove();
        });
      }
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

  void _showGameEndAds() {
    Future.delayed(const Duration(milliseconds: 1000), () async {
      // まずインタースティシャル広告を表示
      if (AdManager.shouldShowAds && AdManager.isInterstitialAdReady) {
        await AdManager.showInterstitialAd();
      }
      
      // その後リワード広告ダイアログを表示
      _showRewardedAdDialog();
    });
  }

  void _showRewardedAdDialog() {
    if (!AdManager.shouldShowAds) return;
    
    showDialog(
      context: context,
      barrierDismissible: false, // ダイアログ外タップで閉じない
      builder: (context) => AlertDialog(
        title: const Text('リワード広告'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('リワード広告を見ると、今日は広告が表示されなくなります。'),
            SizedBox(height: 16),
            Text(
              '広告を見ますか？',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _showRewardedAd();
            },
            child: const Text('広告を見る'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRewardedAd() async {
    try {
      final rewardEarned = await AdManager.showRewardedAd();
      if (rewardEarned) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('今日は広告が表示されません！')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('広告の視聴に失敗しました。')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  void _showHint() {
    if (!widget.isNPC || gameOver) return;
    bool isPlayerTurn = (widget.playerGoesFirst && currentPlayer == 1) || 
                       (!widget.playerGoesFirst && currentPlayer == 2);
    if (!isPlayerTurn) return;
    
    // リワード広告を表示してヒントを提供
    _showHintRewardedAd();
  }

  void _showHintRewardedAd() async {
    print('_showHintRewardedAd called');
    
    if (!AdManager.isRewardedAdReady) {
      print('Rewarded ad not ready');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('リワード広告の準備中です。しばらく待ってから再度お試しください。'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    print('Showing rewarded ad...');
    bool rewardEarned = await AdManager.showRewardedAd();
    print('Reward earned: $rewardEarned');
    
    if (rewardEarned) {
      // リワード獲得時、ヒントを表示
      print('Calling _displayHint...');
      _displayHint();
    } else {
      print('Reward not earned');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('リワード広告を最後まで視聴してください。'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _displayHint() {
    print('_displayHint called');
    
    // 最善手を計算
    List<List<int>> validMoves = [];
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (isValidMove(i, j)) {
          validMoves.add([i, j]);
        }
      }
    }
    
    print('Valid moves count: ${validMoves.length}');
    
    if (validMoves.isEmpty) {
      print('No valid moves found');
      return;
    }
    
    List<int> bestMove = _selectStrategicMove(validMoves);
    print('Best move: $bestMove');
    
    setState(() {
      _hintMove = bestMove;
    });
    
    print('Hint move set: $_hintMove');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('リワード広告を視聴しました！最適な一手を赤色で表示しています'),
        duration: Duration(seconds: 3),
      ),
    );
    
    // 5秒後にヒントを消す（リワード広告視聴の報酬なので少し長めに）
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _hintMove = null;
        });
        print('Hint cleared after 5 seconds');
      }
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
          // ヒントボタン（AI対戦時のみ表示）
          if (widget.isNPC && !gameOver && 
              ((widget.playerGoesFirst && currentPlayer == 1) || 
               (!widget.playerGoesFirst && currentPlayer == 2)))
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              onPressed: _showHint,
              tooltip: 'リワード広告を視聴してヒントを表示',
            ),
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
    bool isValid = isValidMove(row, col);
    bool isNPCTurn = widget.isNPC && 
                     ((widget.playerGoesFirst && currentPlayer == 2) || 
                      (!widget.playerGoesFirst && currentPlayer == 1));
    bool isHint = _hintMove != null && _hintMove![0] == row && _hintMove![1] == col;
    
    // デバッグ用：ヒントが設定されている場合のみログ出力
    if (_hintMove != null && row == 0 && col == 0) {
      print('Building cell at (0,0), hint move: $_hintMove, isHint: $isHint');
    }
    
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
              ? (isHint
                  ? Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent, width: 3),
                      ),
                    )
                  : (isValid ? _buildHintDot() : null))
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

  void _saveGameResult() async {
    // プレイヤー名を取得（簡易版）
    String playerName = 'プレイヤー';
    // 勝者を判定
    bool playerWon = false;
    if (widget.isNPC) {
      // AI対戦の場合
      if (widget.playerGoesFirst) {
        // プレイヤーが黒の場合
        playerWon = blackScore > whiteScore;
      } else {
        // プレイヤーが白の場合
        playerWon = whiteScore > blackScore;
      }
    } else {
      // 二人プレイの場合、黒の勝ちを記録
      playerWon = blackScore > whiteScore;
    }
    // スコアを決定（勝者のスコア）
    int finalScore = playerWon 
        ? (widget.playerGoesFirst ? blackScore : whiteScore)
        : (widget.playerGoesFirst ? whiteScore : blackScore);
    final entry = RankingEntry(
      playerName: playerName,
      score: finalScore,
      difficulty: widget.difficulty,
      isNPC: widget.isNPC,
      date: DateTime.now(),
      playerWon: playerWon,
    );
    // ローカルランキングのみ保存
    await RankingManager.saveLocalRanking(entry);
  }
}

class MoveScore {
  final List<int> move;
  final double score;

  MoveScore(this.move, this.score);
} 