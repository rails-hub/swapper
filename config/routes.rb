Swapper::Application.routes.draw do
  match 'api/register' => 'user#register_api', via: [:post]
  match 'api/upload_pic' => 'user#upload_pic', via: [:post]
  match 'api/download_pic' => 'user#download_pic', via: [:get]
  match 'api/user_images' => 'user#user_images', via: [:get]
  match 'api/like_pic' => 'user#like_pic', via: [:post]
  match 'api/report_pic' => 'user#report_pic', via: [:post]
  match 'api/friends' => 'user#friends', via: [:get]
  match 'api/chat_user' => 'user#chat_user', via: [:post]
  match 'api/get_chat' => 'user#get_chat', via: [:get]
  match 'api/get_chat_images' => 'user#get_chat_images', via: [:get]
  match 'api/load_prev_message' => 'user#load_prev_message', via: [:get]

  root to: "home#index"
 end
