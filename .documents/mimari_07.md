📱 USER ACTION: Trash butonuna bas
    ↓
🎨 UI Layer: _trashMail(mail, index)
    ↓
🎨 Provider: mailProvider.notifier.trashMail(mailId, email)
    ↓
🎯 UseCase: mailActionsUseCase.trashMail(params)
    ↓ (validation)
🎯 UseCase: _repository.trashMail(id, email)
    ↓
💾 Repository: _remoteDataSource.trashMail(id, email)
    ↓
💾 DataSource: ApiEndpoints.buildGmailTrashUrl()
    ↓
💾 DataSource: _apiClient.post(trashUrl)
    ↓
🔧 Network: HTTP POST request
    ↓
🌍 Backend: route.ts → handleTrashOperation()
    ↓
🌍 Backend: Gmail API "move to trash"
    ↓
⬅️ SUCCESS RESPONSE
    ↓
💾 Repository: Success(null) return
    ↓
🎯 UseCase: Result<void> return
    ↓
🎨 Provider: _removeMail(mailId) // Local state update
    ↓
🎨 UI: Mail item listeden kaybolur + SnackBar