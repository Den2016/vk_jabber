unit gForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, EncdDecd,
  Vcl.ExtDlgs, Vcl.Imaging.jpeg;

type
  TGalleryForm = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    OpenPictureDialog1: TOpenPictureDialog;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GalleryForm: TGalleryForm;

implementation

{$R *.dfm}

end.
