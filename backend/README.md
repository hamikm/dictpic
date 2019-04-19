Backend for tapdef app. Entire backend is currently on AWS in the `aws_backend` directory, but I started to transition some lambdas to Google Cloud, since they are just proxies for Google vision and translation APIs. Turns out that start-up time for functions is way longer than for lambdas, which is why I'm sticking with AWS for now.

The `google_backend` directory contains a 100% working backend for the ocr endpoint, though. It's hooked up to the `hamik@bihedral.com` account.
