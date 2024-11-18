import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_syntax_view/flutter_syntax_view.dart';
import 'package:google_fonts/google_fonts.dart';

class CardHighlight extends StatefulWidget {
  const CardHighlight({
    super.key,
    this.backgroundColor,
    this.header,
    required this.child,
  });

  final Widget? header;
  final Widget child;

  final Color? backgroundColor;

  @override
  State<CardHighlight> createState() => _CardHighlightState();
}

class _CardHighlightState extends State<CardHighlight>
    with AutomaticKeepAliveClientMixin<CardHighlight> {
  bool isOpen = false;
  bool isCopying = false;

  final GlobalKey expanderKey = GlobalKey<ExpanderState>(
    debugLabel: 'Card Expander Key',
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = FluentTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: theme.resources.controlStrokeColorSecondary,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Column(children: [
          Mica(
            backgroundColor: widget.backgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(
                  width: double.infinity,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

const fluentHighlightTheme = {
  'root': TextStyle(
    backgroundColor: Color(0x00ffffff),
    color: Color(0xffdddddd),
  ),
  'keyword': TextStyle(
      color: Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold),
  'selector-tag':
      TextStyle(color: Color(0xffffffff), fontWeight: FontWeight.bold),
  'literal': TextStyle(color: Color(0xffffffff), fontWeight: FontWeight.bold),
  'section': TextStyle(color: Color(0xffffffff), fontWeight: FontWeight.bold),
  'link': TextStyle(color: Color(0xffffffff)),
  'subst': TextStyle(color: Color(0xffdddddd)),
  'string': TextStyle(color: Color(0xffdd8888)),
  'title': TextStyle(color: Color(0xffdd8888), fontWeight: FontWeight.bold),
  'name': TextStyle(color: Color(0xffdd8888), fontWeight: FontWeight.bold),
  'type': TextStyle(color: Color(0xffdd8888), fontWeight: FontWeight.bold),
  'attribute': TextStyle(color: Color(0xffdd8888)),
  'symbol': TextStyle(color: Color(0xffdd8888)),
  'bullet': TextStyle(color: Color(0xffdd8888)),
  'built_in': TextStyle(color: Color(0xffdd8888)),
  'addition': TextStyle(color: Color(0xffdd8888)),
  'variable': TextStyle(color: Color(0xffdd8888)),
  'template-tag': TextStyle(color: Color(0xffdd8888)),
  'template-variable': TextStyle(color: Color(0xffdd8888)),
  'comment': TextStyle(color: Color(0xff777777)),
  'quote': TextStyle(color: Color(0xff777777)),
  'deletion': TextStyle(color: Color(0xff777777)),
  'meta': TextStyle(color: Color(0xff777777)),
  'doctag': TextStyle(fontWeight: FontWeight.bold),
  'strong': TextStyle(fontWeight: FontWeight.bold),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
};

SyntaxTheme getSyntaxTheme(FluentThemeData theme) {
  final syntaxTheme = theme.brightness.isDark
      ? SyntaxTheme.vscodeDark()
      : SyntaxTheme.vscodeLight();

  syntaxTheme.baseStyle = GoogleFonts.firaCode(
    textStyle: syntaxTheme.baseStyle,
  );

  return syntaxTheme;
}
