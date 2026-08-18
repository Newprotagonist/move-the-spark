class Goal < ApplicationRecord
  FREQUENCIES = %w[daily weekly].freeze

  has_many :goal_completions, dependent: :destroy

  before_validation :default_frequency_for_one_off

  validates :title, presence: true
  validates :frequency, inclusion: { in: FREQUENCIES }
  validates :scheduled_hour, inclusion: { in: 0..23 }, allow_nil: true
  validates :active_from, presence: true, if: :recurring?
  validates :scheduled_on, presence: true, unless: :recurring?
  validate :recurring_goals_have_no_scheduled_on
  validate :one_off_goals_are_daily_and_have_no_active_from

  scope :ordered, -> { order(:position, :created_at) }
  scope :not_archived_as_of, ->(date) {
    where(archived_at: nil).or(where(Goal.arel_table[:archived_at].gt(date.end_of_day)))
  }
  scope :recurring_daily, -> { where(recurring: true, frequency: "daily") }
  scope :recurring_weekly, -> { where(recurring: true, frequency: "weekly") }
  scope :one_off, -> { where(recurring: false) }
  scope :archived, -> { where.not(archived_at: nil) }

  # Goals due on a specific calendar day: active recurring daily goals plus
  # one-off goals scheduled for that exact date.
  def self.due_on(date)
    recurring_daily.not_archived_as_of(date).where("active_from <= ?", date)
      .or(one_off.where(scheduled_on: date)).ordered
  end

  # Goals due during the week containing `date` (Monday-based): active
  # recurring weekly goals only — one-off goals are always day-scoped.
  def self.due_in_week(date)
    week_start = date.beginning_of_week
    recurring_weekly.not_archived_as_of(week_start.end_of_week)
      .where("active_from <= ?", week_start.end_of_week).ordered
  end

  def daily?
    frequency == "daily"
  end

  def weekly?
    frequency == "weekly"
  end

  def archived?
    archived_at.present?
  end

  def timer_running?
    current_timer_started_at.present?
  end

  # The GoalCompletion#occurred_on value that represents "this goal, on this
  # occurrence": the exact date for a daily/one-off goal, the week's Monday
  # for a weekly goal.
  def occurrence_date(reference_date)
    weekly? ? reference_date.beginning_of_week : reference_date
  end

  # Matches by title (not goal_id) per spec: an ad-hoc one-off goal retyped
  # with the same title on different days counts toward the same average as
  # a true recurring goal.
  def average_duration_seconds
    GoalCompletion.joins(:goal)
      .where(goals: { title: title })
      .where.not(duration_seconds: nil)
      .average(:duration_seconds)
  end

  private

  def default_frequency_for_one_off
    self.frequency = "daily" if !recurring? && frequency.blank?
  end

  def recurring_goals_have_no_scheduled_on
    return unless recurring?

    errors.add(:scheduled_on, "must be blank for a recurring goal") if scheduled_on.present?
  end

  def one_off_goals_are_daily_and_have_no_active_from
    return if recurring?

    errors.add(:frequency, "must be daily for a one-off goal") if frequency.present? && frequency != "daily"
    errors.add(:active_from, "must be blank for a one-off goal") if active_from.present?
  end
end
