Swapper::Application.routes.draw do
  match 'api/register' => 'user#register_api', via: [:post]
  match 'api/upload_pic' => 'user#upload_pic', via: [:post]
  match 'api/download_pic' => 'user#download_pic', via: [:get]
  match 'api/user_images' => 'user#user_images', via: [:get]
  match 'api/like_pic' => 'user#like_pic', via: [:post]
  match 'api/report_pic' => 'user#report_pic', via: [:post]
  match 'api/friends' => 'user#friends', via: [:get]

  root to: "home#index"
 end
