module ApplicationHelper
  def profile_picture_tag(user, classes: "")
    if user.profile_picture_url.present?
      image_tag(user.profile_picture_url,
                alt: "Profile picture",
                class: "#{classes} rounded-full size-10 border-2 border-stone-400", referrerpolicy: "no-referrer"
      )
    else
      content_tag :div, class: "text-gray-50 border-2 border-slate-600 rounded-full" do
        heroicon "user-circle", class: "h-8 w-8 mx-auto text-slate-600"
      end
    end
  end
end
