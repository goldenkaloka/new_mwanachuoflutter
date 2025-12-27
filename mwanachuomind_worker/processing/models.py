from django.db import models
import uuid

class DocumentUpload(models.Model):
    title = models.CharField(max_length=255)
    file = models.FileField(upload_to='uploads/')
    course_id = models.CharField(max_length=255, help_text="Supabase UUID for the course")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title
