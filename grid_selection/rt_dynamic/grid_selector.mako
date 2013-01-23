<%inherit file='tool_form.mako' />
%if app.config.enable_grid_selector:
    <div class="tool_form_body">
        <input type="submit" class="btn btn-primary" name="runtool-btn" value="">
    </div>
%endif

