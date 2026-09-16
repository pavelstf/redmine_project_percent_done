get 'projects/:project_id/percent_done',
    :to => 'project_percent_done#show',
    :as => 'project_percent_done'
get 'projects/:project_id/percent_done/history',
    :to => 'project_percent_done#history',
    :as => 'project_percent_done_history'

post 'admin/project_percent_done/history/preview',
     :to => 'project_percent_done_admin#preview',
     :as => 'project_percent_done_history_preview'
post 'admin/project_percent_done/history/capture',
     :to => 'project_percent_done_admin#capture',
     :as => 'project_percent_done_history_capture'
post 'admin/project_percent_done/history/test_email',
     :to => 'project_percent_done_admin#test_email',
     :as => 'project_percent_done_history_test_email'
get 'projects/:project_id/percent_done/history/purge_preview',
    :to => 'project_percent_done_admin#purge_preview',
    :as => 'project_percent_done_history_purge_preview'
delete 'projects/:project_id/percent_done/history',
       :to => 'project_percent_done_admin#purge',
       :as => 'project_percent_done_history_purge'
