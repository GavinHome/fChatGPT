class ChatInfo {
  String createAt;
  String title;
  String content;
  int isDone; // 0:未开始 1:进行中 2:完成

  ChatInfo({this.createAt = '', this.title = '', this.content = '', this.isDone = 0});
}
