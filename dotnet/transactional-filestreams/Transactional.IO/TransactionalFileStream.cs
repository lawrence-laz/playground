namespace Transactional.IO;

public sealed class TransactionalFileStream : FileStream
{
    private string _tempFilePath;
    private string _originalFilePath;
    private FileStream _tempFileStream;
    private bool _isCommitted;
    private bool _disposedValue;
    private string? _backupFilePath;

    public TransactionalFileStream(string filePath, FileMode mode)
        : base(CreateTempCopy(filePath, out var tempFilePath), mode)
    {
        _originalFilePath = filePath;
        _tempFilePath = tempFilePath;
        _tempFileStream = new FileStream(_tempFilePath, FileMode.Open);
    }

    private static string CreateTempCopy(string filePath, out string tempFilePath)
    {
        tempFilePath = filePath + DateTime.Now.ToFileTime() + ".tmp";
        File.Copy(filePath, tempFilePath);
        return tempFilePath;
    }

    public void Commit()
    {
        _backupFilePath = _originalFilePath + DateTime.Now.ToFileTime() + ".original.tmp";
        File.Copy(_originalFilePath, _backupFilePath);
        File.Move(_tempFilePath, _originalFilePath, overwrite: true);
        File.Delete(_backupFilePath);
        _isCommitted = true;
        _tempFileStream.Close();
    }

    private void Rollback()
    {
        File.Delete(_tempFilePath);
        if (_backupFilePath is not null)
        {
            File.Delete(_backupFilePath);
        }
    }

    protected override void Dispose(bool disposing)
    {
        if (!_disposedValue)
        {
            if (disposing)
            {
                if (!_isCommitted)
                {
                    Rollback();
                }
                _tempFileStream.Dispose();
            }
            _disposedValue = true;
        }
        base.Dispose(disposing);
    }
}

