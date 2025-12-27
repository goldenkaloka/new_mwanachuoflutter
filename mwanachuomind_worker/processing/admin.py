from django.contrib import admin
from .models import DocumentUpload
import os
from supabase import create_client
from django.core.exceptions import ValidationError
from django.contrib import messages

@admin.register(DocumentUpload)
class DocumentUploadAdmin(admin.ModelAdmin):
    list_display = ('title', 'course_id', 'created_at')

    def save_model(self, request, obj, form, change):
        # 1. Save local file first to getting path
        super().save_model(request, obj, form, change)
        
        try:
            # 2. Setup Supabase
            url = os.environ.get('SUPABASE_URL')
            key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')
            if not url or not key:
                raise Exception("Missing Supabase credentials")
            
            supabase = create_client(url, key)
            
            # 3. Upload to Storage
            file_path = obj.file.path
            file_name = os.path.basename(file_path)
            # Create a unique path: {course_id}/{timestamp}.pdf roughly or just random
            # Actually let's use the file name but make sure it's unique-ish on Supabase side if needed
             # But usually we want folders. Let's start with 'uploads/{file_name}'
             # Or better, match what Flutter does? 
             # Flutter does: '${user.id}/${uuid.v4()}.${fileExt}'
             # Here let's use 'admin_uploads/{file_name}'
            
            import time
            storage_path = f"admin_uploads/{int(time.time())}_{file_name}"
            
            with open(file_path, 'rb') as f:
                 supabase.storage.from_('mwanachuomind_docs').upload(storage_path, f)
            
            # 4. Insert row in documents
            # We need the user ID. But admin user is not in Supabase auth.
            # We'll fetch the first user from auth.users or just use a placeholder UUID if FK constraint allows?
            # documents table has no FK on created_by usually? Let's check schema.
            # Checking recent schema dump: created_by is usually UUID but might be nullable?
            # Schema dump above didn't show created_by. It showed id, course_id, title, file_path, metadata, timestamps.
            # So created_by might be missing or in metadata? 
            # Reviewing: {"column_name":"metadata","data_type":"jsonb","is_nullable":"YES"}
            # The schema output above did NOT list 'created_by'. 
            # I will assume it's NOT checking FK for now.
            
            doc_data = {
                'title': obj.title,
                'course_id': obj.course_id, # Must be valid UUID
                'file_path': storage_path,
                'metadata': {'source': 'django_admin'}
            }
            
            res = supabase.table('documents').insert(doc_data).execute()
            
            messages.success(request, f"Successfully uploaded to Supabase: {storage_path}")
            
            # 5. Cleanup local file ?
            # logic to delete is safer in post_delete or manually here
            if os.path.exists(file_path):
                 os.remove(file_path)
                 
        except Exception as e:
            # Delete the local object too if remote fails?
            obj.delete()
            if os.path.exists(obj.file.path):
                 os.remove(obj.file.path)
            messages.error(request, f"Upload Failed: {str(e)}")
            # Re-raise so admin shows error page or just handled?
            # raising ValidationError allows admin to show nice error
            # raise ValidationError(f"Supabase Upload Failed: {str(e)}")
