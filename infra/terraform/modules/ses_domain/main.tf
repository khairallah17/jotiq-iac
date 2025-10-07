resource "aws_ses_domain_identity" "this" {
  domain = var.domain
}

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

resource "aws_route53_record" "verification" {
  count  = var.create_route53_records ? 1 : 0
  name    = "_amazonses.${aws_ses_domain_identity.this.domain}"
  type    = "TXT"
  zone_id = var.hosted_zone_id
  ttl     = 600
  records = [aws_ses_domain_identity.this.verification_token]
}

resource "aws_route53_record" "dkim" {
  count   = var.create_route53_records ? 3 : 0
  name    = "${aws_ses_domain_dkim.this.dkim_tokens[count.index]}._domainkey.${aws_ses_domain_identity.this.domain}"
  type    = "CNAME"
  zone_id = var.hosted_zone_id
  ttl     = 600
  records = ["${aws_ses_domain_dkim.this.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "spf" {
  count  = var.create_route53_records ? 1 : 0
  name    = var.domain
  type    = "TXT"
  zone_id = var.hosted_zone_id
  ttl     = 600
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_ses_identity_notification_topic" "bounce" {
  identity = aws_ses_domain_identity.this.arn
  notification_type = "Bounce"
  topic_arn = var.sns_topic_arn
  include_original_headers = false
}

resource "aws_ses_identity_notification_topic" "complaint" {
  identity = aws_ses_domain_identity.this.arn
  notification_type = "Complaint"
  topic_arn = var.sns_topic_arn
  include_original_headers = false
}

resource "aws_ses_identity_notification_topic" "delivery" {
  identity = aws_ses_domain_identity.this.arn
  notification_type = "Delivery"
  topic_arn = var.sns_topic_arn
  include_original_headers = false
}

resource "aws_ses_domain_identity_verification" "this" {
  count      = var.create_route53_records ? 1 : 0
  domain     = aws_ses_domain_identity.this.domain
  depends_on = var.create_route53_records ? [aws_route53_record.verification[0]] : []
}
