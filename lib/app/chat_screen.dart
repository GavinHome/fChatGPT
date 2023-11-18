import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'adapter/chart_adapter.dart';
import 'common/eventbus.dart';
import 'common/platform.dart';
import 'model/chat_info.dart';
import 'common/uuid.dart';

const smallSpacing = 10.0;
const colDivider = SizedBox(height: 10);
const double widthConstraint = 450;

/// [ChatScreen]
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Column(
      children: [
        const Expanded(child: ChatPage()),
        Padding(
          padding: isMobile()
              ? const EdgeInsets.only(top: 20, bottom: 20)
              : const EdgeInsets.only(top: 10, bottom: 10),
          child: const ChatInput(),
        )
      ],
    ));
  }
}

/// [ChatPage]
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  ScrollController scrollController = ScrollController();
  _ChatPageState();

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      ChatView(scrollController: scrollController),
      colDivider,
    ];
    List<double?> heights = List.filled(children.length, null);

    return FocusTraversalGroup(
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.zero,
            sliver: SliverList(
              delegate: BuildSlivers(
                heights: heights,
                builder: (context, index) {
                  return _CacheHeight(
                    heights: heights,
                    index: index,
                    child: children[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [ChatView]
class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class UserInputEvent {
  String input;

  UserInputEvent(this.input);
}

class ScrollBottomEvent {
  ScrollBottomEvent();
}

class _ChatViewState extends State<ChatView> {
  List<ChatInfo> chats = [];
  bool loading = false;
  StreamSubscription? subscription;
  StreamSubscription? subscription1;

  _ChatViewState() {
    subscription =
        EventBusManager.eventBus.on<UserInputEvent>().listen((event) {
      setState(() {
        chats.add(ChatInfo(
            title: event.input, createAt: '2023-11-14 20:52:00', content: ''));
      });

      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.scrollController.animateTo(
                widget.scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              ));
    });

    subscription1 =
        EventBusManager.eventBus.on<ScrollBottomEvent>().listen((event) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.scrollController.animateTo(
                widget.scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              ));
    });
  }

  @override
  void initState() {
    super.initState();

    loading = true;
    getHistoryChats().then((value) => {
          setState(() {
            chats = value;
            loading = false;
          })
        });
  }

  @override
  void dispose() {
    if (subscription != null) {
      subscription!.cancel();
    }
    if (subscription1 != null) {
      subscription1!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatGroup(
        label: '',
        children: <Widget>[...chats.map((e) => Chat(state: e)).toList()]);
  }

  Future<List<ChatInfo>> getHistoryChats() async {
    final list = [
      ...List<int>.generate(8, (index) => Random().nextInt(10))
          .map((e) => ChatInfo(
              createAt: '2023-11-07 16:31:18',
              title: '列举一些你的特长吧',
              content:
                  '我是一个语言模型，所以我的特长是自然语言处理，我可以回答你的问题，并为你提供有关各种主题的信息。我的知识非常广泛，所以我可以回答各种各样的问题，请尽情提问吧！',
              isDone: 2))
          .toList()
    ];
    return compute((message) => list, "");
  }
}

/// [ChatGroup]
class ChatGroup extends StatelessWidget {
  const ChatGroup({super.key, required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Center(
            child: Column(
              children: [
                //Text(label, style: Theme.of(context).textTheme.titleLarge),
                //colDivider,
                ...children
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [Chat]
class Chat extends StatefulWidget {
  const Chat({super.key, required this.state});

  final ChatInfo state;

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  @override
  void initState() {
    super.initState();

    if (widget.state.isDone == 0) {
      OpenAiChart()
          .fetchAnswer(OpenAiChartRequest(id: id, question: widget.state.title))
          .then((res) async {
        setState(() {
          widget.state.isDone = 1;
          widget.state.content = '';
        });

        var content = res.answer;
        if (content.isNotEmpty) {
          content = content.replaceAll('\n\n', '\r\n');
          var firstPosition = content.indexOf('\r\n');
          if (firstPosition > -1) {
            var firstLine = content.substring(0, firstPosition + 2);
            if (firstLine != '') {
              _streamController.sink.add(firstLine);
              await Future.delayed(const Duration(seconds: 1));
              EventBusManager.eventBus.fire(ScrollBottomEvent());
              content = content.substring(firstPosition + 2);
            }
          } else {
            if (content.length < 100) {
              _streamController.sink.add(content);
              await Future.delayed(const Duration(seconds: 1));
              EventBusManager.eventBus.fire(ScrollBottomEvent());
              content = '';
            }
          }

          var offset = 1;
          while (content.isNotEmpty) {
            // 分段获取
            var current = content.substring(0, offset);
            if (current != '') {
              _streamController.sink.add(current);
              await Future.delayed(const Duration(milliseconds: 20));
              EventBusManager.eventBus.fire(ScrollBottomEvent());
            }

            // 余下内容
            content = content.substring(offset);
          }
        }

        setState(() {
          widget.state.isDone = 2;
          EventBusManager.eventBus.fire(ScrollBottomEvent());
        });
      });
    }
  }

  final StreamController<String> _streamController = StreamController();
  @override
  Widget build(BuildContext context) {
    return ChatDecoration(
      label: widget.state.createAt,
      tooltipMessage: widget.state.createAt,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.person_3_outlined, size: 16),
                        ),
                        Expanded(
                            child: Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(widget.state.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium)))
                      ],
                    ),
                    colDivider,
                    const Divider(key: Key('divider')),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(3.0),
                              child: Image.asset(
                                'lib/assets/images/chatgpt-icon-user-green.png',
                                height: 16,
                              )),
                        ),
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: _getChartAnswerText(
                              context, widget.state, _streamController),
                        ))
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _getChartAnswerText(BuildContext context, ChatInfo state,
      StreamController<String> streamController) {
    if (state.isDone == 0) {
      return const Icon(Icons.more_horiz_outlined, size: 16);
    } else if (state.isDone == 1) {
      return StreamBuilder<String>(
        stream: streamController.stream,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            state.content += snapshot.data ?? '';
            return Text(state.content,
                style: Theme.of(context).textTheme.bodyMedium);
          }
        },
      );
    } else if (state.isDone == 2) {
      return Text(state.content, style: Theme.of(context).textTheme.bodyMedium);
    } else {
      return Text(state.content, style: Theme.of(context).textTheme.bodyMedium);
    }
  }
}

/// [ChatDecoration]
class ChatDecoration extends StatefulWidget {
  const ChatDecoration({
    super.key,
    required this.label,
    required this.child,
    this.tooltipMessage = '',
  });

  final String label;
  final Widget child;
  final String? tooltipMessage;

  @override
  State<ChatDecoration> createState() => _ChatDecorationState();
}

class _ChatDecorationState extends State<ChatDecoration> {
  final focusNode = FocusNode();
  double _widthConstraint = widthConstraint;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _widthConstraint = _getWidthFromMediaQuery(context);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: smallSpacing),
        child: Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints.tightFor(width: _widthConstraint),
              child: Focus(
                focusNode: focusNode,
                canRequestFocus: true,
                child: GestureDetector(
                  onTapDown: (_) {
                    focusNode.requestFocus();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Tooltip(
                              message: widget.tooltipMessage,
                              child: const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 5.0),
                                  child: Icon(Icons.access_time, size: 16))),
                          Text(widget.label,
                              style: Theme.of(context).textTheme.labelMedium),
                        ],
                      ),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5.0, vertical: 20.0),
                          child: Center(
                            child: widget.child,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [ChatInput]
class ChatInput extends StatefulWidget {
  const ChatInput({super.key});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controllerOutlined = TextEditingController();
  double _widthConstraint = widthConstraint;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _widthConstraint = _getWidthFromMediaQuery(context);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: _widthConstraint),
      child: Padding(
        padding: const EdgeInsets.all(smallSpacing),
        child: TextField(
          controller: _controllerOutlined,
          style: Theme.of(context).textTheme.bodySmall,
          onSubmitted: (value) {
            EventBusManager.eventBus.fire(UserInputEvent(value));
            _controllerOutlined.text = '';
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.message_outlined),
            suffixIcon: _ClearButton(controller: _controllerOutlined),
            hintText: '随便问...',
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => controller.clear(),
      );
}

/// [BuildSlivers]
class BuildSlivers extends SliverChildBuilderDelegate {
  BuildSlivers({
    required NullableIndexedWidgetBuilder builder,
    required this.heights,
  }) : super(builder, childCount: heights.length);

  final List<double?> heights;

  @override
  double? estimateMaxScrollOffset(int firstIndex, int lastIndex,
      double leadingScrollOffset, double trailingScrollOffset) {
    return heights.reduce((sum, height) => (sum ?? 0) + (height ?? 0))!;
  }
}

/// [_CacheHeight]
class _CacheHeight extends SingleChildRenderObjectWidget {
  const _CacheHeight({
    super.child,
    required this.heights,
    required this.index,
  });

  final List<double?> heights;
  final int index;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderCacheHeight(
      heights: heights,
      index: index,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderCacheHeight renderObject) {
    renderObject
      ..heights = heights
      ..index = index;
  }
}

class _RenderCacheHeight extends RenderProxyBox {
  _RenderCacheHeight({
    required List<double?> heights,
    required int index,
  })  : _heights = heights,
        _index = index,
        super();

  List<double?> _heights;
  List<double?> get heights => _heights;
  set heights(List<double?> value) {
    if (value == _heights) {
      return;
    }
    _heights = value;
    markNeedsLayout();
  }

  int _index;
  int get index => _index;
  set index(int value) {
    if (value == index) {
      return;
    }
    _index = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    super.performLayout();
    heights[index] = size.height;
  }
}

/// [_getWidthFromMediaQuery]
/// get width value:
/// 1. 450(only mobile)
/// 2. 450(only the width of web or desktop is less than 650)
/// 3. 0.618 times of the media size(only web or desktop)
double _getWidthFromMediaQuery(context) {
  final double width = MediaQuery.of(context).size.width;
  if (isWeb() || isDesktop()) {
    if (width < 650) {
      return widthConstraint;
    }

    return width * 0.618;
  }

  return widthConstraint;
}
