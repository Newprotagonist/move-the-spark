class AppointmentsController < ApplicationController
  before_action :set_appointment, only: [ :edit, :update, :destroy ]
  before_action -> { @sheet = true }, only: [ :new, :create, :edit, :update ]

  def index
    @appointments = Appointment.upcoming
  end

  def new
    @appointment = Appointment.new(starts_at: parse_date(params[:date])&.to_time&.change(hour: 9))
  end

  def create
    @appointment = Appointment.new(appointment_params)
    if @appointment.save
      # Not referer-based: the referer for a create POST is the "new" form
      # page itself. Go to the day the appointment is actually on instead.
      redirect_to day_path(date: @appointment.starts_at.to_date), notice: "Rendez-vous créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @appointment.update(appointment_params)
      redirect_to redirect_target, notice: "Rendez-vous mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @appointment.destroy
    redirect_to redirect_target, notice: "Rendez-vous supprimé."
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(:title, :starts_at, :location, :notes, :reminder_lead_minutes)
  end

  def redirect_target
    request.referer || appointments_path
  end
end
