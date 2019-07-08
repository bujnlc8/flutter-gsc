class Gsc {
  int id;
  int audioId;
  String workTitle;
  String workAuthor;
  String content;
  String workDynasty;
  String layout;
  String translation;
  String intro;
  String foreword;
  String appreciation;
  String shortContent;
  String playUrl;
  String masterComment;
  String annotation;

  void setShortContent() {
    // 句号
    var periodIndex = this.content.indexOf("。");
    if (periodIndex == -1) {
      // 感叹号
      var exclamatoryMarkIndex = this.content.indexOf("！");
      if (exclamatoryMarkIndex == -1) {
        // 问号
        var questionMarkIndex = this.content.indexOf("？");
        this.shortContent = this.content.substring(0, questionMarkIndex + 1);
      } else
        [
          (this.shortContent =
              this.content.substring(0, exclamatoryMarkIndex + 1))
        ];
    } else {
      this.shortContent = this.content.substring(0, periodIndex + 1);
    }
  }

  Gsc(Map gsc) {
    this.id = gsc["id"];
    this.content = gsc["content"];
    this.workAuthor = gsc["work_author"];
    this.workTitle = gsc["work_title"];
    this.workDynasty = gsc["work_dynasty"];
    this.layout = gsc["layout"];
    this.translation = gsc["translation"];
    this.intro = gsc["intro"];
    this.foreword = gsc["foreword"];
    this.appreciation = gsc["appreciation"];
    this.masterComment = gsc["master_comment"];
    this.audioId = gsc["audio_id"];
    this.annotation = gsc["annotation"];

    setShortContent();

    if (this.layout == 'indent') {
      this.content =
          "　　" + this.content.replaceAll(new RegExp(r"\n|\t"), "\n" + "　　");
    }
    if (this.translation.length > 0) {
      this.translation =
          "　　" + this.translation.replaceAll(new RegExp(r"\n|\t"), "\n" + "　　");
    }
    if (this.foreword.length > 0) {
      this.foreword = "　　 " + this.foreword;
    }
    if (this.masterComment.length > 0) {
      this.masterComment = "　　" +
          this.masterComment.replaceAll(new RegExp(r"\n|\t"), "\n" + "　　");
    }
    if (this.intro.length > 0) {
      this.intro =
          "　　" + this.intro.replaceAll(new RegExp(r"\n|\t"), "\n" + "　　");
    }
    if (this.annotation.length > 0) {
      this.annotation =
          "　　" + this.annotation.replaceAll(new RegExp(r"\n|\t"), "\n" + "　　");
    }
    if (this.appreciation.length > 0) {
      this.appreciation = "　　" +
          this.appreciation.replaceAll(new RegExp(r"\n|\t"), "\n" + "　　");
    }
    if (this.audioId > 0) {
      this.playUrl = "https://songci.nos-eastchina1.126.net/audio/{}.m4a"
          .replaceAll("{}", this.audioId.toString());
    }
  }
}
