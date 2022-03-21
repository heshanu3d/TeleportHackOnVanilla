Func print($content)
    ;~ _GUICtrlRichEdit_AppendText($log, $content & @CR)
    _GUICtrlEdit_AppendText($log, $content & @CRLF)
    ConsoleWrite($content & @CR)
EndFunc