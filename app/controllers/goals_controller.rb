class GoalsController < ApplicationController
  before_action :set_goal, only: [ :edit, :update, :destroy, :complete, :uncomplete ]

  def new
    @goal = Goal.new(
      recurring: params[:recurring] == "true",
      frequency: params[:frequency].presence || "daily",
      scheduled_on: params[:scheduled_on].presence && Date.parse(params[:scheduled_on])
    )
  end

  def create
    @goal = Goal.new(goal_params)
    if @goal.save
      redirect_to redirect_target, notice: "Objectif créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @goal.update(goal_params)
      redirect_to redirect_target, notice: "Objectif mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @goal.destroy
    redirect_to redirect_target, notice: "Objectif supprimé."
  end

  def complete
    occurred_on = Date.parse(params[:occurred_on])
    @goal.goal_completions.find_or_create_by!(occurred_on: occurred_on) do |completion|
      completion.completed_at = Time.current
      completion.points_awarded = 0
    end

    respond_to_toggle(occurred_on)
  end

  def uncomplete
    occurred_on = Date.parse(params[:occurred_on])
    @goal.goal_completions.find_by(occurred_on: occurred_on)&.destroy

    respond_to_toggle(occurred_on)
  end

  private

  def set_goal
    @goal = Goal.find(params[:id])
  end

  def goal_params
    params.require(:goal).permit(:title, :description, :frequency, :recurring, :scheduled_on, :active_from)
  end

  def redirect_target
    request.referer || root_path
  end

  def respond_to_toggle(occurred_on)
    respond_to do |format|
      format.html { redirect_to redirect_target }
      format.turbo_stream do
        completion = @goal.goal_completions.find_by(occurred_on: occurred_on)
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@goal, occurred_on.to_s),
          partial: "goals/goal",
          locals: { goal: @goal, reference_date: occurred_on, completion: completion }
        )
      end
    end
  end
end
