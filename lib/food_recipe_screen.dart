import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'app_colors.dart';
import 'app_navigation_bar.dart';
import 'food_repository.dart';
import 'food_item.dart';

// ★ Gemini接続時にコメントを外す (pubspec.yamlに google_generative_ai を追加)
import 'package:google_generative_ai/google_generative_ai.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

// 画面の状態:初期 / 読み込み中 / 完了 / エラー
enum RecipePhase { idle, loading, done, error }

class _RecipeScreenState extends State<RecipeScreen> {
  //Variable
  RecipePhase _phase = RecipePhase.idle;
  Set<String> _selected = {};
  bool _expanded = false; // 「すべて表示」の開閉
  String _recipeText = '';
  Timer? _msgTimer;
  int _msgIndex = 0;

  // ★ trueの間はAPIを呼ばず疑似データで動く。Gemini接続できたらfalseに
  static const bool _useMock = false;

  static const _loadingMsgs = [
    '冷蔵庫の食材を確認しています...',
    'レシピを考えています...',
    '作り方をまとめています...',
  ];

  static const _mockRecipe = '''豚こま肉とキャベツを使った「豚こまとキャベツのうま塩卵炒め」はいかがでしょうか？

■ 材料（2人分）
・豚こま肉 … 200g
・キャベツ … 1/4玉
・卵 … 2個

■ 作り方
1. キャベツはざく切りにします。
2. 溶き卵を炒り卵にして取り出します。
3. 豚こま肉を炒め、キャベツを加えてさっと炒めます。
4. 味付けして炒り卵を戻したら完成です。''';

  @override
  void initState() {
    super.initState();
    //賞味期限が近い食材(3日以内) を自動で選択
    _selected = FoodRepository.getAll()
        .where((i) => _daysUntil(i.expiry) <= 3)
        .map((i) => i.name)
        .toSet();
  }

  @override
  void dispose() {
    _msgTimer?.cancel();
    super.dispose();
  }

  int _daysUntil(DateTime expiry) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(expiry.year, expiry.month, expiry.day);
    return target.difference(today).inDays;
  }

  //GenerateRecipe
  Future<void> _generate() async {
    if (_selected.isEmpty || _phase == RecipePhase.loading) return;

    setState(() {
      _phase = RecipePhase.loading;
      _msgIndex = 0;
    });
    //読み込み中メッセージを1.7秒ごとに切り替え
    _msgTimer = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      setState(() => _msgIndex = (_msgIndex + 1) % _loadingMsgs.length);
    });

    try {
      final text = _useMock ? await _fetchMock() : await _fetchGemini();
      final settingsBox = Hive.box('settingsBox');
      await settingsBox.put('lastRecipe', text);
      if (!mounted) return;
      setState(() {
        _recipeText = text;
        _phase = RecipePhase.done;
      });
    } catch (e) {
      //429 (リクエスト過多) や通信エラーはここに来る
      if (!mounted) return;
      print(e);
      setState(() => _phase = RecipePhase.error);
    } finally {
      _msgTimer?.cancel();
    }
  }

  //疑似API: ３秒待ってから固定テキストを返す
  Future<String> _fetchMock() async {
    await Future.delayed(const Duration(seconds: 3));
    return _mockRecipe;
  }

  // ★ Gemini接続の実装例(_useMock = false にして使う)
  Future<String> _fetchGemini() async {
    final model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
    );
    final prompt =
        '次の食材を使った家庭向けレシピを一つ、日本語で提案してください。'
        '材料(2人分)　と作り方とポイントを含めてください。　'
        '食材: ${_selected.join('、')}';
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? 'レシピを取得できませんでした';
  }

  void _cancel() {
    _msgTimer?.cancel();
    setState(() => _phase = RecipePhase.idle);
  }

  @override
  Widget build(BuildContext context) {
    final all = FoodRepository.getAll();
    //折りたたみ中は「期限が近い or 選択中」だけ表示
    final visible = _expanded
        ? all
        : all
              .where(
                (i) => _daysUntil(i.expiry) <= 3 || _selected.contains(i.name),
              )
              .toList();
    final hiddenCount = all.length - visible.length;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Header
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'レシピ提案',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '冷蔵庫の食材からAIがレシピを考えます',
                    style: TextStyle(fontSize: 13, color: ink2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  _ingredientCard(visible, hiddenCount),
                  const SizedBox(height: 14),
                  _generateButton(),
                  const SizedBox(height: 14),
                  if (_phase == RecipePhase.idle) _idleCard(),
                  if (_phase == RecipePhase.loading) _loadingCard(),
                  if (_phase == RecipePhase.done) _resultCard(),
                  if (_phase == RecipePhase.error) _errorCard(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: 1, // レシピタブ
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
      ),
    );
  }

  //ingredientCard
  Widget _ingredientCard(List<FoodItem> visible, int hiddenCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '使う食材',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ink2,
                ),
              ),
              Text(
                '${_selected.length}個 選択中',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accentInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...visible.map(_ingredientChip),
              //ExpandChip
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFB),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD5D9DE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? '折りたたむ' : 'すべて表示 + $hiddenCount',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: ink2,
                        ),
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: ink2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          const Row(
            children: [
              Icon(Icons.schedule, size: 14, color: ink2),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  '賞味期限が近い食材を自動で選んでいます',
                  style: TextStyle(fontSize: 11.5, color: ink2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //IngredientChip
  Widget _ingredientChip(FoodItem item) {
    final on = _selected.contains(item.name);
    final days = _daysUntil(item.expiry);
    return GestureDetector(
      onTap: () => setState(() {
        on ? _selected.remove(item.name) : _selected.add(item.name);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: on ? accent : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? accent : const Color(0xFFE9EBEE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: on ? Colors.white : const Color(0xFF54595E),
              ),
            ),
            if (days <= 3) ...[
              const SizedBox(width: 6),
              Text(
                'あと$days日',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: on
                      ? Colors.white70
                      : (days <= 1
                            ? const Color(0xFFB33B31)
                            : const Color(0xFF9A6B1A)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  //GenerateButton
  Widget _generateButton() {
    final canGenerate = _selected.isNotEmpty && _phase != RecipePhase.loading;
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: canGenerate ? _generate : null,
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          disabledBackgroundColor: const Color(0xFFAFC9B7),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(
          _phase == RecipePhase.done ? Icons.refresh : Icons.auto_awesome,
          size: 22,
        ),
        label: Text(
          _phase == RecipePhase.done ? 'もう一度提案してもらう' : 'レシピを提案してもらう',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  //IdleCard
  Widget _idleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE0E5)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: accentSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: accent, size: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            '使う食材を選んで、\nAiにレシピを考えてもらいましょう',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.7, color: ink2),
          ),
        ],
      ),
    );
  }

  //LoadingCard
  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF2)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3.5, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            _loadingMsgs[_msgIndex],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '回答が届くまで少し時間がかかることがあります',
            style: TextStyle(fontSize: 12, color: ink2),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: _cancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: ink2,
              side: const BorderSide(color: Color(0xFFE9EBEE)),
            ),
            child: const Text(
              'キャンセル',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  //ResultCard
  Widget _resultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '提案されたレシピ',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    Text(
                      '選択した食材 ${_selected.length}つから生成',
                      style: const TextStyle(fontSize: 11.5, color: ink2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 26, color: Color(0xFFF0F1F3)),
          // レシピ本文(１つの長いテキストをそのまま表示)
          Text(
            _recipeText,
            style: const TextStyle(fontSize: 14, height: 1.95, color: ink),
          ),
          const SizedBox(height: 14),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 14, color: Color(0xFFB3B8BF)),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'AIが生成した内容です。分量や加熱時間は目安として確認してください。',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.6,
                    color: Color(0xFFB3B8BF),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //ErrorCard(429エラーや通信失敗のとき)
  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF2)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFFDECEC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Color(0xFFE5484D),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'レシピを取得できませんでした',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '通信状況を確認して、しばらくしてからもう一度お試しください',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.6, color: ink2),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _generate,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'もう一度試す',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
