enum RevealStyle {
  coin('硬币', '正反抛掷'),
  cards('纸牌', '德州起手牌');

  const RevealStyle(this.title, this.subtitle);

  final String title;
  final String subtitle;
}
