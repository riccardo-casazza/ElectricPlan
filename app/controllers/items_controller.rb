class ItemsController < ApplicationController
  before_action :set_item, only: %i[ show edit update destroy duplicate ]

  # GET /items or /items.json
  def index
    @items = Item.includes(:room, :breaker, :item_type, :input_cable, room: :floor, breaker: { residual_current_device: :electrical_panel })

    # Apply filters
    if params[:dwelling_id].present?
      @items = @items.joins(breaker: { residual_current_device: :electrical_panel }).where(electrical_panels: { dwelling_id: params[:dwelling_id] })
    end

    if params[:electrical_panel_id].present?
      @items = @items.joins(breaker: :residual_current_device).where(residual_current_devices: { electrical_panel_id: params[:electrical_panel_id] })
    end

    if params[:residual_current_device_id].present?
      @items = @items.joins(:breaker).where(breakers: { residual_current_device_id: params[:residual_current_device_id] })
    end

    if params[:breaker_id].present?
      @items = @items.where(breaker_id: params[:breaker_id])
    end

    if params[:room_id].present?
      @items = @items.where(room_id: params[:room_id])
    end

    @items = @items.all
  end

  # GET /items/1 or /items/1.json
  def show
  end

  # GET /items/new
  def new
    @new_item = Item.new
    load_filtered_items
    render :index
  end

  # GET /items/1/edit
  def edit
    load_filtered_items
    @new_item = @item
    render :index
  end

  # POST /items or /items.json
  def create
    @item = Item.new(item_params)

    respond_to do |format|
      if @item.save
        format.html { redirect_to items_path, notice: "Item was successfully created." }
        format.json { render :show, status: :created, location: @item }
      else
        @new_item = @item
        load_filtered_items
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /items/1 or /items/1.json
  def update
    respond_to do |format|
      if @item.update(item_params)
        format.html { redirect_to items_path(filter_params), notice: "Item was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @item }
      else
        @new_item = @item
        load_filtered_items
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1 or /items/1.json
  def destroy
    @item.destroy!

    respond_to do |format|
      format.html { redirect_to items_path, notice: "Item was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # POST /items/1/duplicate
  def duplicate
    @new_item = @item.dup

    respond_to do |format|
      if @new_item.save
        format.html { redirect_to items_path, notice: "Item was successfully duplicated." }
        format.json { render :show, status: :created, location: @new_item }
      else
        format.html { redirect_to items_path, alert: "Failed to duplicate item." }
        format.json { render json: @new_item.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_item
      @item = Item.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def item_params
      params.expect(item: [ :breaker_id, :room_id, :name, :item_type_id, :input_cable_id, :power_watts, :implemented ])
    end

    def filter_params
      params.permit(:dwelling_id, :electrical_panel_id, :residual_current_device_id, :breaker_id, :room_id)
    end
    helper_method :filter_params

    def load_filtered_items
      @items = Item.includes(:room, :breaker, :item_type, :input_cable, room: :floor, breaker: { residual_current_device: :electrical_panel })

      if params[:dwelling_id].present?
        @items = @items.joins(breaker: { residual_current_device: :electrical_panel }).where(electrical_panels: { dwelling_id: params[:dwelling_id] })
      end

      if params[:electrical_panel_id].present?
        @items = @items.joins(breaker: :residual_current_device).where(residual_current_devices: { electrical_panel_id: params[:electrical_panel_id] })
      end

      if params[:residual_current_device_id].present?
        @items = @items.joins(:breaker).where(breakers: { residual_current_device_id: params[:residual_current_device_id] })
      end

      if params[:breaker_id].present?
        @items = @items.where(breaker_id: params[:breaker_id])
      end

      if params[:room_id].present?
        @items = @items.where(room_id: params[:room_id])
      end

      @items = @items.all
    end
end
