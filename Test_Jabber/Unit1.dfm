object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 742
  ClientWidth = 911
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    911
    742)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 24
    Width = 25
    Height = 13
    Caption = 'Login'
  end
  object Label2: TLabel
    Left = 200
    Top = 24
    Width = 22
    Height = 13
    Caption = 'Pass'
  end
  object Label3: TLabel
    Left = 168
    Top = 59
    Width = 12
    Height = 13
    Caption = 'To'
  end
  object Message: TLabel
    Left = 24
    Top = 106
    Width = 42
    Height = 13
    Caption = 'Message'
  end
  object Label4: TLabel
    Left = 155
    Top = 81
    Width = 22
    Height = 13
    Caption = 'Pass'
  end
  object Edit1: TEdit
    Left = 47
    Top = 21
    Width = 147
    Height = 21
    TabOrder = 0
    Text = 'cashmaster-test@lada-nf.ru'
  end
  object Edit2: TEdit
    Left = 231
    Top = 21
    Width = 121
    Height = 21
    TabOrder = 1
    Text = 'lada110303'
  end
  object Button1: TButton
    Left = 384
    Top = 19
    Width = 75
    Height = 25
    Caption = 'Connect'
    TabOrder = 2
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 748
    Top = 19
    Width = 75
    Height = 25
    Caption = 'Clear'
    TabOrder = 3
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 488
    Top = 19
    Width = 75
    Height = 25
    Caption = 'Disconnect'
    TabOrder = 4
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 592
    Top = 19
    Width = 75
    Height = 25
    Caption = 'Get roster'
    TabOrder = 5
    OnClick = Button4Click
  end
  object Edit3: TEdit
    Left = 186
    Top = 58
    Width = 135
    Height = 21
    TabOrder = 6
    Text = 'aa@lada-nf.ru'
  end
  object Button5: TButton
    Left = 432
    Top = 65
    Width = 75
    Height = 25
    Caption = 'Subscribe OK'
    TabOrder = 7
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 351
    Top = 65
    Width = 75
    Height = 25
    Caption = 'Ask subscribe'
    TabOrder = 8
    OnClick = Button6Click
  end
  object Button7: TButton
    Left = 513
    Top = 65
    Width = 75
    Height = 25
    Caption = 'Unsubscribe'
    TabOrder = 9
    OnClick = Button7Click
  end
  object Edit4: TEdit
    Left = 72
    Top = 103
    Width = 697
    Height = 21
    TabOrder = 10
  end
  object Send: TButton
    Left = 784
    Top = 101
    Width = 75
    Height = 25
    Caption = 'Send'
    TabOrder = 11
    OnClick = SendClick
  end
  object Panel1: TPanel
    Left = 9
    Top = 128
    Width = 894
    Height = 606
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Panel1'
    TabOrder = 12
    object Panel2: TPanel
      Left = 688
      Top = 1
      Width = 205
      Height = 343
      Align = alRight
      Caption = 'Panel2'
      TabOrder = 0
      object Memo2: TMemo
        Left = 1
        Top = 1
        Width = 203
        Height = 341
        Align = alClient
        ScrollBars = ssBoth
        TabOrder = 0
      end
    end
    object Panel3: TPanel
      Left = 1
      Top = 344
      Width = 892
      Height = 261
      Align = alBottom
      Caption = 'Panel3'
      TabOrder = 1
      object Memo3: TMemo
        Left = 1
        Top = 1
        Width = 890
        Height = 259
        Align = alClient
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
    object Panel4: TPanel
      Left = 1
      Top = 1
      Width = 687
      Height = 343
      Align = alClient
      Caption = 'Panel4'
      TabOrder = 2
      object Memo1: TMemo
        Left = 1
        Top = 1
        Width = 685
        Height = 341
        Align = alClient
        ScrollBars = ssBoth
        TabOrder = 0
      end
    end
  end
  object Button8: TButton
    Left = 40
    Top = 56
    Width = 75
    Height = 25
    Caption = 'Swap'
    TabOrder = 13
    OnClick = Button8Click
  end
  object Edit5: TEdit
    Left = 186
    Top = 78
    Width = 135
    Height = 21
    TabOrder = 14
    Text = '1234'
  end
  object RESTRequest1: TRESTRequest
    Client = RESTClient1
    Params = <>
    SynchronizedEvents = False
    Left = 456
    Top = 208
  end
  object RESTClient1: TRESTClient
    Params = <>
    HandleRedirects = True
    Left = 560
    Top = 216
  end
end
