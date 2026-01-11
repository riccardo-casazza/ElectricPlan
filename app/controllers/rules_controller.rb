class RulesController < ApplicationController
  before_action :set_rule, only: %i[ show edit update destroy verify ]

  # GET /rules or /rules.json
  def index
    @rules = Rule.all
  end

  # GET /rules/1 or /rules/1.json
  def show
  end

  # GET /rules/new
  def new
    @new_rule = Rule.new
    @rules = Rule.all
    render :index
  end

  # GET /rules/1/edit
  def edit
    @rules = Rule.all
    @new_rule = @rule
    render :index
  end

  # POST /rules or /rules.json
  def create
    @rule = Rule.new(rule_params)

    respond_to do |format|
      if @rule.save
        format.html { redirect_to rules_path, notice: "Rule was successfully created." }
        format.json { render :show, status: :created, location: @rule }
      else
        @new_rule = @rule
        @rules = Rule.all
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @rule.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rules/1 or /rules/1.json
  def update
    respond_to do |format|
      if @rule.update(rule_params)
        format.html { redirect_to rules_path, notice: "Rule was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @rule }
      else
        @new_rule = @rule
        @rules = Rule.all
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @rule.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rules/1 or /rules/1.json
  def destroy
    @rule.destroy!

    respond_to do |format|
      format.html { redirect_to rules_path, notice: "Rule was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # POST /rules/1/verify
  def verify
    verifier = RuleVerifier.new(@rule)
    result = verifier.verify

    if result[:success]
      if result[:violations_count] > 0
        flash[:alert] = "Verification complete: Found #{result[:violations_count]} violation(s) out of #{result[:total_checked]} resources checked."
      else
        flash[:notice] = "Verification complete: All #{result[:total_checked]} resources comply with this rule."
      end
    else
      flash[:alert] = "Verification failed: #{result[:error]}"
    end

    # Force a redirect to ensure fresh data is loaded
    redirect_to rules_path, status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_rule
      @rule = Rule.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def rule_params
      params.expect(rule: [ :description, :rule, :applies_to ])
    end
end
