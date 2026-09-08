import os

# 1. Update models.py PortfolioItem
models_path = r'c:\Users\Haram\Desktop\buolot-man\backend\apps\accounts\models.py'
with open(models_path, 'r', encoding='utf-8') as f:
    models_content = f.read()

new_portfolio_fields = """
    video_url = models.URLField(blank=True, max_length=500)
    project_location = models.CharField(max_length=255, blank=True)
    client_company = models.CharField(max_length=255, blank=True)
"""

if 'video_url = models.URLField' not in models_content:
    target_port = "    project_value = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)"
    models_content = models_content.replace(target_port, target_port + new_portfolio_fields)
    
    with open(models_path, 'w', encoding='utf-8') as f:
        f.write(models_content)
    print("models.py updated with new Portfolio fields")
else:
    print("models.py already has new Portfolio fields")

