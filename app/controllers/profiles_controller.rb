# Full profile page (points, level, streak, focus hours, activity heatmap,
# settings entry point) lands in a later pass — this renders the basics
# already loaded by ApplicationController#load_gamification_summary so the
# "Moi" tab has somewhere real to go.
class ProfilesController < ApplicationController
  def show
  end
end
